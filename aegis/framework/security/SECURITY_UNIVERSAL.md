# Diretrizes de Segurança — Universal

> **OBRIGATÓRIO**: Leia este arquivo inteiro antes de implementar qualquer endpoint, formulário, upload ou lógica que envolva dados do usuário, pagamento ou estado mutável. Estas regras não são opcionais. Aplique em TODO o código do projeto, independente do framework ou linguagem.
>
> Este documento é agnóstico de projeto. Adapte os exemplos de código ao seu stack, mas nunca ignore os princípios.

---

## 1. Race Conditions

Teste race conditions em **qualquer operação** que envolva:

- Saldo, créditos ou tokens
- Compra, pagamento ou transação financeira
- Curtida, favorito, voto ou qualquer estado que faz toggle
- Geração ou processamento de conteúdo (evitar processar 2x o mesmo job)
- Atualização de status (pedido, assinatura, ticket, etc.)
- Estoque, vagas, ingressos ou qualquer recurso limitado
- Criação de recursos únicos (username, slug, código de cupom)

**Como testar**: Dispare requisições simultâneas idênticas E com variações (IDs diferentes, quantidades diferentes, combinações de parâmetros). Faça isso em TODOS os endpoints que fazem escrita.

**Princípios de implementação**:
- Use transações com nível de isolamento adequado (Serializable para operações financeiras)
- Use locks otimistas (versioning) ou pessimistas (SELECT FOR UPDATE) dependendo do caso
- Para filas de processamento, use idempotency keys — se o mesmo job chegar 2x, execute apenas 1x
- Para webhooks de gateways de pagamento, sempre verifique se o recurso já foi processado antes de agir

```
// Pseudocódigo — adapte ao seu ORM/linguagem
transaction(isolationLevel: SERIALIZABLE) {
  resource = findById(id)
  if (resource.status != EXPECTED_STATUS) throw AlreadyProcessedError
  resource.status = NEW_STATUS
  save(resource)
}
```

**Atenção especial com webhooks**: Gateways (Stripe, Mercado Pago, PayPal, PagSeguro, Asaas, etc.) podem enviar o mesmo webhook múltiplas vezes. Use o ID do evento como idempotency key e armazene eventos já processados.

---

## 2. IDOR (Insecure Direct Object Reference)

Valide IDOR em **todo endpoint que recebe ID** — sempre cheque no backend se o recurso pertence ao usuário autenticado.

```
// ❌ ERRADO — qualquer usuário acessa qualquer recurso
resource = findById(params.id)

// ✅ CORRETO — verifica propriedade
resource = findByIdAndOwner(params.id, authenticatedUser.id)
if (!resource) return 404
```

**Onde aplicar (sem exceção)**:
- Todo endpoint que recebe ID de recurso na URL (path param ou query param)
- Todo endpoint que retorna dados de um recurso específico
- Todo endpoint que modifica ou deleta um recurso
- Endpoints de download de arquivos privados
- Endpoints de webhook — validar assinatura criptográfica, nunca confiar apenas no payload
- Listagens — sempre filtrar por owner, nunca retornar todos os registros

**Regra de ouro**: Se o endpoint recebe um ID, o backend DEVE verificar que `resource.ownerId === currentUser.id` (ou papel equivalente). Sem exceção.

---

## 3. Validação de Input

Limitar tamanho de input em **todos os campos, sem exceção**. Usar uma biblioteca de schema validation (zod, yup, joi, pydantic, etc.) em todo endpoint.

**Princípios**:
- Defina o schema ANTES de escrever a lógica — todo campo tem tipo, tamanho mínimo, tamanho máximo e formato esperado
- Rejeite a requisição inteira se qualquer campo falhar na validação
- Retorne erros genéricos ao client, erros detalhados apenas nos logs

**Regras obrigatórias para todo campo**:

| Tipo de campo | Validações obrigatórias |
|---------------|------------------------|
| String (texto livre) | min, max, trim, sanitizar HTML |
| String (enum) | Lista fixa de valores permitidos |
| Email | Formato de email + max 254 chars |
| URL | Protocolo https + hostname allowlist |
| Número | min, max, integer vs float |
| Data | Formato válido, range aceitável (não futura se inapropriado) |
| Booleano | Apenas true/false, sem coerção de strings |
| Array | maxItems, validar cada item individualmente |
| Objeto | Validar cada propriedade, rejeitar propriedades extras |

**Regras adicionais**:
- Sanitizar HTML em qualquer campo que aceite texto livre — tanto no client (DOMPurify) quanto no server (sanitize-html ou equivalente)
- Nunca interpolar input do usuário em: queries SQL (use parameterized queries), prompts de IA (evitar prompt injection), templates de email (evitar header injection), comandos shell (nunca fazer isso), expressões regulares (evitar ReDoS)
- Campos de nome/texto pessoal: permitir apenas letras (incluindo acentos/unicode), espaços, hífens e apóstrofos
- Limitar rate de submissão de formulários (ex: 1 submit a cada 5 segundos por IP)
- Payloads JSON: limitar tamanho total do body (ex: max 1MB para APIs normais, configurar no middleware)
- Query strings: validar e limitar — não aceitar parâmetros inesperados

---

## 4. Upload de Arquivos

Validar uploads por **MIME type E magic bytes**, não só extensão. Extensão é trivial de falsificar.

**Camadas de validação (aplicar TODAS)**:

1. **Tamanho**: Limite máximo por tipo (ex: 10MB para imagens, 50MB para documentos). Rejeitar antes de processar.

2. **Magic bytes**: Ler os primeiros bytes do arquivo para identificar o tipo real. Use bibliotecas: `file-type` (Node), `python-magic` (Python), `mimetype` (Go).

3. **Extensão**: Verificar como redundância, nunca como única validação.

4. **Decodificação**: Tentar processar o arquivo como o tipo esperado (ex: abrir como imagem com sharp/Pillow). Se falhar, rejeitar — pode ser um arquivo malicioso disfarçado.

5. **Resolução/dimensões** (para imagens): Limitar resolução máxima para evitar pixel flood attacks (ex: max 8000x8000).

**Regras de armazenamento**:
- Nunca servir uploads diretamente do seu servidor — use storage externo (S3, R2, GCS) com URLs assinadas e TTL
- Renomear arquivo com UUID — nunca usar o nome original (evitar path traversal)
- Strip EXIF/metadata antes de armazenar — fotos podem conter GPS, dados do dispositivo, informações pessoais
- Processar e re-encodar o arquivo antes de armazenar (ex: re-comprimir imagem com sharp/Pillow) — elimina payloads escondidos
- Verificar antivírus em uploads de documentos (se aplicável ao seu caso de uso)
- Definir Content-Disposition como `attachment` para downloads, nunca `inline` para tipos perigosos

**Nunca**:
- Armazenar uploads na mesma pasta que o código da aplicação
- Executar ou interpretar conteúdo de uploads
- Confiar no Content-Type do header HTTP (é definido pelo client)

---

## 5. URLs e Recursos Externos

Restringir URLs ao seu domínio e **não aceitar URLs arbitrárias do client**.

```
// Pseudocódigo
function isValidResourceUrl(url):
  parsed = parseUrl(url)
  if parsed.hostname NOT IN allowedHosts: return false
  if parsed.protocol != "https": return false
  if parsed.search contains suspicious params: return false
  return true
```

**Nunca**:
- Aceitar URLs arbitrárias do client para renderizar imagens ou fazer embed (SSRF)
- Fazer fetch server-side de URLs fornecidas pelo usuário sem validação rigorosa
- Usar query strings para passar paths de arquivo internos
- Redirecionar para URLs fornecidas pelo usuário sem validar contra allowlist (Open Redirect)
- Confiar em URLs de callbacks/webhooks sem validar assinatura

**Se PRECISAR fazer fetch de URL externa** (ex: metadata de link):
- Allowlist de domínios
- Timeout curto (max 5s)
- Limitar tamanho da resposta
- Não seguir redirects para domínios fora da allowlist
- Bloquear IPs privados/internos (127.0.0.1, 10.x.x.x, 192.168.x.x, etc.) — previne SSRF

---

## 6. Lógica de Negócio e Timing

Revise toda lógica que envolve **janelas de tempo** para evitar exploração de timing.

**Pagamentos e transações financeiras**:
- Confirmação do gateway → só então executar a ação (entregar produto, ativar assinatura, etc.)
- Nunca confiar no client para informar que o pagamento foi feito
- Validar valor pago vs. valor esperado no server (evitar manipulação de preço)
- Links/tokens de acesso a recursos pagos devem ter TTL
- URLs assinadas com expiração para downloads de conteúdo pago

**Reembolso / Cancelamento**:
- Definir janela clara e validar no backend
- Verificar condições antes de aprovar (downloads feitos, uso do serviço, etc.)
- Revogar acessos imediatamente após reembolso

**Vouchers, convites e códigos**:
- Gerar com entropia suficiente (UUID v4 ou superior, nunca sequencial)
- Definir TTL e número máximo de resgates
- Validar que não foi resgatado antes de processar
- Rate limit para tentativas de resgate (evitar brute force)

**Promoções e cupons**:
- Validar no backend — nunca confiar no client
- Limite de uso por cupom E por usuário
- Verificar validade no server (não confiar no timezone do client)
- Logar uso para auditoria

**Assinaturas e trials**:
- Verificar status da assinatura no server a cada request protegido
- Não confiar em flags locais/cookies para determinar acesso
- Tratar webhook de cancelamento imediatamente

---

## 7. Autenticação e Sessão

**Regras fundamentais**:
- Nunca implemente autenticação do zero — use bibliotecas consolidadas (NextAuth, Auth.js, Passport, Django Auth, etc.)
- Tokens JWT: TTL curto (15min–1h), refresh tokens com rotação
- Sessões: armazenar server-side (Redis/DB), cookie httpOnly + secure + sameSite
- Rate limit em login: max 5 tentativas em 15 minutos por IP/email
- Lockout após tentativas excessivas (temporário, com reset por email)
- Nunca retornar mensagens diferentes para "email não existe" vs. "senha errada" (evitar enumeração de usuários)
- Logout deve invalidar a sessão server-side, não apenas apagar o cookie
- Forçar re-autenticação para ações sensíveis (alterar email, alterar senha, deletar conta)
- Implementar CSRF protection em todos os formulários que mudam estado

**API Keys (se aplicável)**:
- Armazenar apenas o hash, nunca o valor plain text
- Permitir múltiplas keys por usuário com nomes descritivos
- Permitir revogação individual
- Logar uso para auditoria

---

## 8. Honeypots e Defesa em Profundidade

Implementar honeypots como defesa adicional de baixo custo:

**Honeypot em formulários**:
- Adicione um campo hidden no formulário (ex: `name="website"` ou `name="company_url"`)
- O campo fica invisível para humanos (CSS: `position: absolute; left: -9999px`)
- Bots preenchem todos os campos — se esse campo vier preenchido, é bot
- Retorne 200 com response fake (não alertar o bot que foi detectado)

**Endpoints falsos (decoy)**:
- Crie rotas que parecem sensíveis mas retornam dados fictícios e logam o acesso:
  - `/api/admin/users`, `/api/v2/export`, `/api/internal/config`
  - `/wp-admin/`, `/phpmyadmin/`, `/.env`, `/xmlrpc.php`
- Todo acesso a esses endpoints → alerta no monitoramento + block IP temporário
- Custo de implementação: quase zero. Custo para o atacante: tempo desperdiçado.

**Defesa em profundidade (princípio geral)**:
- Nunca confie em uma única camada de proteção
- Valide no client E no server
- Rate limit na edge E na aplicação
- Autentique E verifique autorização em cada camada

---

## 9. Headers de Segurança

Configurar os seguintes headers em TODAS as respostas HTTP. Adapte ao seu framework:

| Header | Valor | O que previne |
|--------|-------|---------------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Downgrade para HTTP |
| `X-Frame-Options` | `SAMEORIGIN` | Clickjacking |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing |
| `Referrer-Policy` | `origin-when-cross-origin` | Leak de URLs sensíveis |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Acesso indevido a hardware |
| `X-DNS-Prefetch-Control` | `on` | Performance (não segurança) |

**Content-Security-Policy (CSP)**:
- Comece restritivo: `default-src 'self'`
- Adicione exceções conforme necessário para scripts/imagens de terceiros (analytics, CDN, payment gateway, ads)
- Nunca use `unsafe-inline` para scripts em produção se possível — use nonces
- Se precisar de `unsafe-inline` (ex: para styled-components), documente o motivo
- Teste a CSP no modo report-only antes de ativar

**CORS**:
- Nunca use `Access-Control-Allow-Origin: *` em APIs autenticadas
- Defina explicitamente os domínios permitidos
- Cuidado com credenciais: `Access-Control-Allow-Credentials: true` exige origin explícito

---

## 10. Rate Limiting

Aplique rate limiting em **todos os endpoints públicos**. Adapte os limites ao seu caso de uso.

**Referência de limites por tipo de endpoint**:

| Tipo de endpoint | Limite sugerido | Janela |
|------------------|----------------|--------|
| Login / Registro | 5–10 requests | 15 minutos |
| Upload de arquivo | 5 requests | 1 minuto |
| Processamento / Geração | 3–5 requests | 1 minuto |
| Checkout / Pagamento | 10 requests | 1 minuto |
| APIs de leitura (autenticadas) | 60 requests | 1 minuto |
| APIs de leitura (públicas) | 30 requests | 1 minuto |
| Webhooks | 30 requests | 1 minuto |
| Páginas públicas | 120 requests | 1 minuto |
| Password reset | 3 requests | 15 minutos |

**Implementação**:
- Use Redis/Upstash para rate limiting distribuído
- Identifique por IP + userId (se autenticado)
- Retorne `429 Too Many Requests` com header `Retry-After`
- Considere rate limiting progressivo: primeiro request rápido, depois delay crescente
- Para APIs públicas de alto tráfego, considere rate limiting na edge (Cloudflare, Vercel Edge, etc.)

---

## 11. Dados Sensíveis e Privacidade

### Nunca armazenar:
- Dados de cartão de crédito (delegue ao gateway de pagamento)
- Senhas em plain text (use bcrypt/argon2 com salt)
- Tokens de API em plain text no banco (armazene apenas o hash)
- Dados temporários de processamento após conclusão (ex: fotos usadas para gerar arte)

### Armazenar com cuidado:
- Email: necessário para comunicação → encriptar em repouso se possível
- Dados pessoais: mínimo necessário para o serviço funcionar (princípio de minimização)
- Logs: nunca logar senhas, tokens, dados de cartão, dados pessoais sensíveis

### Privacidade e conformidade (LGPD / GDPR):
- Política de privacidade clara e acessível no site
- Opção de deletar dados a qualquer momento (direito ao esquecimento)
- Consentimento explícito para emails de marketing (checkbox não pré-marcado)
- Base legal documentada para cada tipo de dado coletado
- Notificar usuários em caso de breach
- Exportação de dados pessoais em formato legível (direito de portabilidade)
- Distinguir dados necessários para o serviço vs. dados de marketing

### Secrets e variáveis de ambiente:
- Nunca commitar secrets no repositório (use .env + .gitignore)
- Rotacionar secrets periodicamente
- Usar secret managers em produção (Vault, AWS Secrets Manager, Vercel env, etc.)
- Diferentes secrets para dev/staging/production

---

## 12. Logging e Monitoramento

**O que logar (sempre)**:
- Tentativas de autenticação (sucesso e falha)
- Acessos a recursos protegidos
- Erros de validação (input inválido pode indicar ataque)
- Acessos a honeypots
- Rate limit hits
- Erros de pagamento
- Alterações em dados sensíveis (email, senha, permissões)

**O que NUNCA logar**:
- Senhas (nem em caso de erro)
- Tokens de sessão / JWT / API keys
- Dados de cartão de crédito
- Dados pessoais completos (logar apenas IDs/hashes)

**Formato**:
- Log estruturado (JSON) com: timestamp, level, message, userId, requestId, IP, userAgent
- Incluir requestId para correlacionar logs de uma mesma requisição
- Alertas automáticos para: picos de erros 4xx/5xx, acessos a honeypots, rate limit excessivo, tentativas de login repetidas

---

## 13. Dependências e Supply Chain

- Mantenha dependências atualizadas — rode `npm audit` / `pip audit` / equivalente regularmente
- Use lockfile (package-lock.json, poetry.lock, etc.) e commite no repositório
- Revise changelogs antes de atualizar dependências major
- Prefira dependências com manutenção ativa e muitos downloads/stars
- Considere usar Dependabot / Renovate para atualizações automáticas
- Nunca instale pacotes de sources não confiáveis
- Para pacotes críticos (auth, crypto, payment), prefira bibliotecas oficiais do provedor

---

## 14. Checklist de Segurança por Feature

Antes de considerar **qualquer feature** pronta para produção, verificar:

### Input e dados
- [ ] Todos os inputs validados com schema validation (tipos, tamanhos, formatos)
- [ ] HTML sanitizado em campos de texto livre
- [ ] Sem interpolação de input do usuário em queries/prompts/templates/comandos
- [ ] Payload size limitado

### Autorização
- [ ] IDOR verificado — recurso pertence ao usuário autenticado
- [ ] Permissões/roles verificados no backend (não confiar no client)
- [ ] Ações sensíveis exigem re-autenticação

### Proteção
- [ ] Rate limiting aplicado no endpoint
- [ ] CSRF protection em formulários que mudam estado
- [ ] Transação com lock para operações de escrita concorrentes

### Dados
- [ ] Sem dados sensíveis no response que não deveriam estar lá
- [ ] Sem console.log/print com dados do usuário em produção
- [ ] Erro genérico para o client, erro detalhado apenas nos logs
- [ ] Dados temporários limpos após processamento

### Upload (se aplicável)
- [ ] Validado por magic bytes + extensão + decodificação
- [ ] Tamanho limitado
- [ ] Arquivo renomeado com UUID
- [ ] EXIF/metadata removidos
- [ ] Armazenado em storage externo com URL assinada

### URLs e recursos externos (se aplicável)
- [ ] URLs validadas contra allowlist de domínios
- [ ] Sem SSRF — sem fetch de URLs arbitrárias server-side
- [ ] Redirects validados contra allowlist

### Infraestrutura
- [ ] Headers de segurança presentes
- [ ] CORS configurado restritivamente
- [ ] Secrets em variáveis de ambiente (não hardcoded)
- [ ] Logging adequado sem dados sensíveis

---

## 15. Referência Rápida: Top 10 Erros Mais Comuns

| # | Erro | Consequência | Prevenção |
|---|------|-------------|-----------|
| 1 | Não validar tamanho de input | DoS, buffer overflow, custos de storage | Schema validation em tudo |
| 2 | Confiar no client para autorização | Acesso indevido a dados alheios | IDOR check no backend sempre |
| 3 | Validar upload só por extensão | Upload de malware disfarçado | Magic bytes + decodificação |
| 4 | Fetch de URL fornecida pelo usuário | SSRF, acesso a rede interna | Allowlist + bloqueio de IPs privados |
| 5 | Webhook sem verificação de assinatura | Ações fraudulentas | Validar HMAC/assinatura sempre |
| 6 | Sem rate limit em login | Brute force de senhas | 5 tentativas / 15 min |
| 7 | Sem transação em operação financeira | Race condition, duplicação | Serializable + idempotency key |
| 8 | Logar dados sensíveis | Leak de senhas/tokens via logs | Nunca logar credentials |
| 9 | Secrets no repositório | Comprometimento total | .env + secret manager |
| 10 | CSP ausente ou permissiva | XSS, data exfiltration | CSP restritiva desde o dia 1 |
