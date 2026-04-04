# NossoBebê — Diretrizes de Segurança

> **OBRIGATÓRIO**: Leia este arquivo inteiro antes de implementar qualquer endpoint, formulário, upload ou lógica de pagamento. Estas regras não são opcionais e devem ser aplicadas em TODO o código do projeto.

---

## 1. Race Conditions

Teste race conditions em **qualquer operação** que envolva:
- Saldo ou créditos
- Compra ou pagamento
- Curtida, favorito ou qualquer estado que faz toggle
- Geração de conteúdo (evitar gerar 2x para o mesmo pedido)
- Atualização de status de pedido

**Como testar**: Disparar requisições simultâneas idênticas E com variações (produtos diferentes, quantidades diferentes). Usar mutex/lock no banco de dados para operações críticas.

**Implementação**:
```typescript
// Use transações Prisma com isolamento para operações críticas
await prisma.$transaction(async (tx) => {
  const order = await tx.order.findUnique({ where: { id: orderId } });
  if (order.status !== 'PENDING') throw new Error('Order already processed');
  // ... processar
}, { isolationLevel: 'Serializable' });
```

**Para webhooks de pagamento**: Use idempotency keys. O Mercado Pago pode enviar o mesmo webhook múltiplas vezes. Verifique se o pedido já foi processado antes de gerar conteúdo.

---

## 2. IDOR (Insecure Direct Object Reference)

Validar IDOR em **todo endpoint que recebe ID** — sempre checar no backend se o recurso pertence ao usuário autenticado.

```typescript
// ❌ ERRADO — qualquer um acessa qualquer pedido
const order = await prisma.order.findUnique({ where: { id: params.orderId } });

// ✅ CORRETO — verifica propriedade
const order = await prisma.order.findFirst({
  where: { id: params.orderId, email: session.user.email }
});
if (!order) return NextResponse.json({ error: 'Not found' }, { status: 404 });
```

**Aplicar em**:
- `/api/generate/*` — verificar que o orderId pertence ao usuário
- `/entrega/[orderId]` — verificar propriedade antes de mostrar downloads
- `/api/webhooks/*` — validar assinatura do webhook (não confiar no payload)
- Qualquer endpoint que retorne dados de um pedido específico

---

## 3. Validação de Input

Limitar tamanho de input em **todos os campos, sem exceção**.

```typescript
// Use zod para validação em todo endpoint
import { z } from 'zod';

const createOrderSchema = z.object({
  babyName: z.string().min(1).max(50).trim(),
  birthDate: z.string().date().refine(d => new Date(d) <= new Date(), 'Data não pode ser futura'),
  birthTime: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  birthWeight: z.string().max(10).optional(),
  birthCity: z.string().min(2).max(100).trim(),
  parentNames: z.string().max(100).trim().optional(),
  musicStyle: z.enum(['mpb', 'instrumental', 'gospel', 'classico', 'lofi', 'pop']),
  musicTone: z.enum(['alegre', 'suave']),
  specialWords: z.string().max(200).trim().optional(),
  artStyle: z.enum(['aquarela', 'ilustracao', 'minimalista', 'retro']),
  email: z.string().email().max(254),
});

// Em todo API route:
const parsed = createOrderSchema.safeParse(body);
if (!parsed.success) {
  return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
}
```

**Regras adicionais**:
- Sanitizar HTML em qualquer campo que aceite texto livre (DOMPurify no client, sanitize-html no server)
- Nunca interpolar input do usuário em prompts de IA sem sanitização — evitar prompt injection
- Campos de nome: filtrar caracteres especiais, manter apenas letras, espaços, hífens e acentos
- Limitar rate de submissão de formulários (1 submit a cada 5 segundos por IP)

---

## 4. Upload de Arquivos

Validar uploads por **MIME type E magic bytes**, não só extensão.

```typescript
import fileType from 'file-type';

async function validateUpload(file: Buffer, filename: string): Promise<boolean> {
  // 1. Verificar tamanho (max 10MB)
  if (file.length > 10 * 1024 * 1024) return false;

  // 2. Verificar magic bytes (real file type)
  const type = await fileType.fromBuffer(file);
  if (!type) return false;

  const allowedMimes = ['image/jpeg', 'image/png', 'image/heic', 'image/heif'];
  if (!allowedMimes.includes(type.mime)) return false;

  // 3. Verificar extensão (redundância)
  const ext = filename.split('.').pop()?.toLowerCase();
  const allowedExts = ['jpg', 'jpeg', 'png', 'heic', 'heif'];
  if (!ext || !allowedExts.includes(ext)) return false;

  // 4. Tentar decodificar como imagem (evitar arquivos maliciosos disfarçados)
  // Use sharp para validar que é uma imagem real
  try {
    const sharp = require('sharp');
    const metadata = await sharp(file).metadata();
    if (!metadata.width || !metadata.height) return false;
    if (metadata.width > 8000 || metadata.height > 8000) return false; // Limitar resolução
  } catch {
    return false;
  }

  return true;
}
```

**Regras adicionais**:
- Nunca servir uploads diretamente — usar Cloudflare R2 com URLs assinadas e TTL
- Renomear arquivo com UUID (nunca usar o nome original)
- Processar imagem com sharp antes de armazenar (strip EXIF, resize, recompress)
- Strip EXIF é especialmente importante: fotos de bebê podem conter localização GPS

---

## 5. URLs e Recursos Externos

Restringir URLs de imagem ao seu domínio e **não aceitar query strings arbitrárias**.

```typescript
// Validar URLs de imagem geradas
function isValidImageUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    const allowedHosts = [
      'r2.nossobebe.com.br',       // Cloudflare R2
      'nossobebe.com.br',           // Próprio domínio
    ];
    return allowedHosts.includes(parsed.hostname) && !parsed.search;
  } catch {
    return false;
  }
}
```

**Nunca**:
- Aceitar URLs arbitrárias do client para renderizar imagens (SSRF)
- Fazer fetch de URLs fornecidas pelo usuário no server-side
- Usar query strings para passar paths de arquivo

---

## 6. Lógica de Negócio e Timing

Revisar lógicas que envolvem **janelas de tempo** para evitar exploração de timing.

**Para pagamentos**:
- Webhook do Mercado Pago confirma → só então inicia geração
- Nunca gerar conteúdo antes da confirmação de pagamento
- Links de download expiram em 30 dias
- URLs assinadas do R2 com TTL de 24h (renovadas sob demanda)

**Para reembolso**:
- Janela de reembolso: 7 dias após compra
- Verificar que a geração não foi baixada mais de 2x antes de aprovar reembolso
- Revogar links de download após reembolso

**Para presentes (modo GIFT)**:
- Voucher de upload posterior: gerar código com UUID v4, TTL de 90 dias
- Validar que o voucher não foi resgatado mais de 1x
- Email de entrega para os pais: nunca incluir dados de pagamento do comprador
- Entrega agendada: validar que a data não é mais que 9 meses no futuro
- O destinatário (pais) deve poder optar por não receber drip content
- Rate limit: max 5 presentes por email de comprador por dia (evitar spam/abuso)

**Para promoções/cupons** (se implementado):
- Validar no backend, nunca confiar no client
- Limite de uso por cupom E por usuário
- Verificar data de validade no server (não confiar no timezone do client)

---

## 7. Honeypots e Defesa em Profundidade

Implementar honeypots como defesa adicional:

```typescript
// Formulário com campo honeypot (hidden, não deve ser preenchido)
<input
  type="text"
  name="website"
  style={{ position: 'absolute', left: '-9999px' }}
  tabIndex={-1}
  autoComplete="off"
/>

// No backend: rejeitar silenciosamente se preenchido
if (body.website) {
  // É um bot — retornar 200 fake para não alertar
  return NextResponse.json({ success: true });
}
```

**Endpoints falsos (decoy)**:
- `/api/admin/users` — retorna dados fictícios e loga o IP
- `/api/v2/export` — idem
- `/wp-admin/` — retorna 200 com HTML fake (consome tempo de scanners WordPress)
- Qualquer acesso a esses endpoints → alerta no Sentry + block IP temporário

---

## 8. Headers de Segurança

Configurar no `next.config.js`:

```javascript
const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://pagead2.googlesyndication.com https://www.googletagmanager.com",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https://r2.nossobebe.com.br https://pagead2.googlesyndication.com",
      "media-src 'self' https://r2.nossobebe.com.br",
      "connect-src 'self' https://api.mercadopago.com https://pagead2.googlesyndication.com",
      "frame-src https://pagead2.googlesyndication.com",
    ].join('; ')
  },
];
```

---

## 9. Rate Limiting

Aplicar em todos os endpoints públicos:

| Endpoint | Limite | Janela |
|----------|--------|--------|
| `POST /api/upload` | 5 requests | 1 minuto |
| `POST /api/generate/*` | 3 requests | 1 minuto |
| `POST /api/checkout` | 10 requests | 1 minuto |
| `GET /api/blog/*` | 60 requests | 1 minuto |
| `POST /api/webhooks/*` | 30 requests | 1 minuto |
| Landing page | 120 requests | 1 minuto |

Usar `@upstash/ratelimit` com Redis (Upstash) ou implementar com Vercel KV.

---

## 10. Dados Sensíveis

### Nunca armazenar:
- Fotos dos bebês após a geração da arte (deletar do storage após processamento)
- Dados de cartão de crédito (Mercado Pago/Stripe cuidam disso)
- Senhas em plain text (se houver sistema de login)

### Armazenar com cuidado:
- Email: necessário para entrega e drip → encriptar em repouso
- Nome do bebê: necessário para o produto → mínimo necessário
- Cidade: necessário para dados do dia → ok armazenar

### LGPD:
- Política de privacidade clara e acessível
- Opção de deletar dados a qualquer momento
- Consentimento explícito para emails de marketing (drip content)
- Base legal: execução de contrato (para o produto) + consentimento (para marketing)

---

## 11. Checklist de Segurança por Feature

Antes de considerar qualquer feature pronta, verificar:

- [ ] Inputs validados com zod (tipos, tamanhos, formatos)
- [ ] IDOR verificado (recurso pertence ao usuário?)
- [ ] Rate limiting aplicado
- [ ] Sem dados sensíveis no response que não deveriam estar lá
- [ ] Sem console.log com dados do usuário
- [ ] Erro genérico para o client, erro detalhado nos logs
- [ ] Transação com lock para operações de escrita críticas
- [ ] Upload validado por magic bytes (se aplicável)
- [ ] URLs de recursos validadas contra allowlist
- [ ] Headers de segurança presentes
