# Plano de Implementação — NossoBebê Platform

## Visão Geral

Implementação incremental da plataforma NossoBebê em Next.js 16+ App Router com TypeScript strict. Cada task constrói sobre a anterior, terminando com todos os componentes integrados. Stack: Supabase (Auth + PostgreSQL + Storage + Realtime), Prisma ORM, Suno v5.5 (principal) + Google Lyria 3 Pro (fallback), Google Imagen 3, Mercado Pago, Resend, PostHog, @upstash/ratelimit, Vercel.

> **OBRIGATÓRIO antes de implementar qualquer task**: Ler `docs/SECURITY copy.md` inteiro e consultar context7 para documentação atualizada das bibliotecas usadas na task.

## Tasks

- [ ] 1. Configuração do projeto e infraestrutura base
  - Inicializar projeto Next.js 16+ com TypeScript strict, Tailwind CSS e ESLint
  - Configurar Prisma com connection string do Supabase PostgreSQL (pgBouncer)
  - Criar `prisma/schema.prisma` com todos os models: `Order`, `Product`, `DripEmail`, `NameEntry`, `BlogPost`, `DayDataCache` — enums `OrderMode`, `OrderStatus`, `ProductType`, `ProductStatus`
  - Executar `prisma migrate dev` e gerar o client Prisma
  - Configurar variáveis de ambiente: `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUNO_API_KEY`, `GOOGLE_IMAGEN_API_KEY`, `MERCADOPAGO_ACCESS_TOKEN`, `MERCADOPAGO_WEBHOOK_SECRET`, `RESEND_API_KEY`, `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, `POSTHOG_API_KEY`
  - Configurar headers de segurança HTTP em `next.config.js` (HSTS, X-Frame-Options, CSP, etc.) conforme `docs/SECURITY copy.md` seção 8
  - Criar `lib/types.ts` com tipos TypeScript principais: `MusicStyle`, `ArtStyle`, `MusicVersion`, `CreateOrderInput`, `GenerationJobPayload`
  - _Requisitos: 10.6_

- [ ] 2. Segurança — Middleware, rate limiting e honeypots
  - [ ] 2.1 Implementar `lib/security/decoy.ts` com funções `handleDecoyAccess`, `banIp`, `checkBannedIp` usando Upstash Redis (`bannedIp:{ip}` com TTL)
  - [ ] 2.2 Implementar `middleware.ts` em Edge Runtime: verificar IP banido via Upstash Redis antes de qualquer request; nunca banir IPs em `/api/webhooks/mercadopago`
  - [ ] 2.3 Implementar `lib/security/rate-limiter.ts` com `@upstash/ratelimit` — sliding window para cada endpoint: upload (5/min), generate (3/min), checkout (10/min), blog (60/min), webhooks (30/min); retornar 429 com header `Retry-After`
  - [ ] 2.4 Implementar `lib/security/idor-guard.ts` com função `assertOrderOwnership(orderId, userEmail)` que busca o pedido e lança 404 se não pertencer ao usuário
  - [ ] 2.5 Criar endpoints decoy: `GET /api/admin/users`, `GET /api/v2/export` (JSON fictício + ban IP 24h); `GET /wp-admin/`, `GET /phpmyadmin/`, `GET /.env` (HTML/texto fake + ban IP 24h) — todos retornam HTTP 200
  - [ ] 2.6 Escrever testes de propriedade para rate limiting
    - **Property 9: Rate limiting retorna 429 com Retry-After**
    - **Valida: Requisitos 10.2, 10.3**
  - [ ] 2.7 Escrever testes de exemplo para decoy endpoints e ban de IP
    - Verificar que acesso a decoy bane o IP no Upstash Redis com TTL correto
    - Verificar que IP banido recebe 403 em todos os endpoints subsequentes
    - Verificar que IPs do Mercado Pago nunca são banidos
    - _Requisitos: 10.7_
  - _Requisitos: 10.2, 10.3, 10.7_

- [ ] 3. Autenticação e Storage com Supabase
  - [ ] 3.1 Implementar `lib/auth/index.ts` com `getSession(request)` e `requireSession(request)` usando `createServerClient` do `@supabase/ssr`; configurar cookies httpOnly
  - [ ] 3.2 Implementar `lib/storage/index.ts` com `uploadFile`, `getSignedUrl`, `deleteFile` usando Supabase Storage; buckets `baby-photos` (TTL 24h) e `pack-files` (TTL 30 dias)
  - [ ] 3.3 Escrever testes de exemplo para Supabase Auth e Storage
    - Verificar que sessão inválida retorna 401 em endpoints protegidos
    - Verificar que URLs assinadas são geradas com TTL correto por bucket
    - _Requisitos: 8.2, 8.3_
  - _Requisitos: 8.2, 8.3, 11.4_

- [ ] 4. Validators Zod e schemas de input
  - [ ] 4.1 Criar `lib/validators/order.ts` com `createOrderSchema` (Zod): todos os campos de `CreateOrderInput` com restrições de tamanho, enums `MusicStyle`/`ArtStyle`, data não futura, data máx 1 ano no passado, data de entrega agendada máx 9 meses no futuro
  - [ ] 4.2 Criar `lib/validators/upload.ts` com schema de validação de upload (tamanho, MIME, dimensões)
  - [ ] 4.3 Criar `lib/validators/checkout.ts` com schema de checkout e upsell (valores fixos no backend: R$39,90, R$9,90, R$19,90)
  - [ ] 4.4 Escrever testes de propriedade para validação de input
    - **Property 2: Validação de input rejeita valores fora do domínio**
    - **Valida: Requisitos 4.5, 4.6, 3.5, 3.6**
  - [ ] 4.5 Escrever testes de propriedade para honeypot
    - **Property 5: Honeypot rejeita bots silenciosamente**
    - **Valida: Requisito 3.7**
  - _Requisitos: 3.5, 3.6, 4.5, 4.6, 3.7_

- [ ] 5. Upload de foto do bebê
  - [ ] 5.1 Implementar `POST /api/upload`: validar tamanho (≤10MB), magic bytes (jpeg/png/heic/heif via `file-type`), processar com `sharp` (verificar dimensões <8000px, strip EXIF), renomear com UUID v4, armazenar no bucket `baby-photos` do Supabase Storage; aplicar rate limit 5/min
  - [ ] 5.2 Escrever testes de propriedade para validação de upload
    - **Property 3: Validação de upload rejeita arquivos inválidos**
    - **Valida: Requisitos 2.1, 2.2, 2.3, 2.4**
  - [ ] 5.3 Escrever testes de exemplo para upload
    - Arquivo >10MB → 400
    - MIME inválido → 400
    - Dimensões >8000px → 400
    - Upload válido → retorna `fileKey` UUID
    - _Requisitos: 2.1–2.8_
  - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 2.8_

- [ ] 6. Criação de pedido e fluxo do formulário
  - [ ] 6.1 Implementar `POST /api/orders`: validar com `createOrderSchema`, checar honeypot (`website`), criar `Order` no banco com status `PENDING_PAYMENT`; autenticação Supabase obrigatória
  - [ ] 6.2 Implementar `lib/security/prompt-sanitizer.ts` com função `sanitizeForPrompt(input: string): string` que remove padrões de prompt injection (instruções de sistema, delimitadores, overrides) de `babyName`, `specialWords`, `giftMessage`
  - [ ] 6.3 Escrever testes de propriedade para sanitização de prompts
    - **Property 10: Sanitização de input antes de prompts de IA**
    - **Valida: Requisito 10.5**
  - [ ] 6.4 Escrever testes de exemplo para criação de pedido
    - Honeypot preenchido → 200 fake, sem pedido no banco
    - Campos inválidos → 400 com erros por campo
    - Pedido válido → retorna `orderId`
    - _Requisitos: 3.1–3.7_
  - _Requisitos: 3.1, 3.2, 3.3, 3.5, 3.6, 3.7, 10.1, 10.5_

- [ ] 7. Checkout e integração Mercado Pago
  - [ ] 7.1 Implementar `lib/payment/mercadopago.ts`: criar preferência de pagamento (Pix, cartão, boleto), calcular valor total no backend a partir da tabela de preços (nunca confiar no cliente), retornar `pixCode`/`pixQrCode`/`redirectUrl`
  - [ ] 7.2 Implementar `POST /api/checkout`: validar `orderId` (IDOR Guard), calcular valor no backend, criar preferência MP, aplicar rate limit 10/min
  - [ ] 7.3 Implementar `POST /api/webhooks/mercadopago`: verificar assinatura HMAC, usar transação Prisma `Serializable` com `SELECT FOR UPDATE`, idempotency key via `Order.paymentId`, disparar job de geração assíncrono, retornar 200 imediatamente
  - [ ] 7.4 Escrever testes de propriedade para idempotência do webhook
    - **Property 1: Idempotência do webhook de pagamento**
    - **Valida: Requisitos 5.5, 5.6, 11.1, 11.2**
  - [ ] 7.5 Escrever testes de propriedade para valor calculado no backend
    - **Property 8: Valor do pedido calculado no backend**
    - **Valida: Requisitos 6A.6, 15.6**
  - [ ] 7.6 Escrever testes de exemplo para checkout e webhook
    - Webhook com assinatura inválida → 401
    - Webhook duplicado → 200 sem reprocessar
    - Valor manipulado pelo cliente → valor correto cobrado
    - _Requisitos: 5.4, 5.5, 5.6, 5.7_
  - _Requisitos: 5.1, 5.2, 5.4, 5.5, 5.6, 5.7, 5.8, 11.1, 11.2_

- [ ] 8. Checkpoint — Verificar segurança base
  - Garantir que todos os testes passam, middleware está ativo, rate limiting funciona, IDOR Guard está integrado. Perguntar ao usuário se há dúvidas antes de prosseguir para geração de conteúdo.

- [ ] 9. Gerador de música (Suno v5.5 + fallback Lyria)
  - [ ] 9.1 Implementar `lib/generators/music.ts` com `generateMusic(opts: MusicGeneratorOptions): Promise<Buffer>`: consultar context7 para API atual do Suno v5.5; retry 3x com backoff (1s, 2s, 4s); fallback automático para Google Lyria 3 Pro em caso de falha; sanitizar `babyName` e `specialWords` antes de interpolar no prompt; timeout 45s por tentativa
  - [ ] 9.2 Implementar prompts distintos para cada versão: Estrela (arranjo acústico/orgânico, letra poética), Lua (mais elementos musicais, letra narrativa), Nuvem (variação de andamento, letra com mais repetição do nome), Sol (tom alegre/animado, letra brincalhona)
  - [ ] 9.3 Escrever testes de exemplo para gerador de música
    - Mock do Suno: verificar que fallback Lyria é acionado na falha após 3 tentativas
    - Verificar que `babyName` e `specialWords` são sanitizados antes do prompt
    - _Requisitos: 6.8, 6.9_
  - _Requisitos: 6.1, 6.8, 6.9, 10.5_

- [ ] 10. Gerador de imagens (Google Imagen 3) e dados do dia
  - [ ] 10.1 Implementar `lib/generators/image.ts` com `generateBabyArt`, `generateWorldPoster`, `generateNameArt` usando Google Imagen 3 (Nano Banana 2); consultar context7 para API atual; retry 3x com backoff (2s, 4s, 8s); resoluções: 3000x3000px (arte/nome) e 3000x4000px (poster)
  - [ ] 10.2 Implementar `lib/generators/day-data.ts` com `fetchDayData(date, city)`: buscar dados de Spotify Charts, OpenWeather History, TMDB, API lunar; cache no Upstash Redis com chave `YYYY-MM-DD_cidade` e TTL 24h; fallback por campo independente
  - [ ] 10.3 Implementar `lib/generators/pdf.ts` para gerar PDF do Guia dos Primeiros Meses com identidade visual NossoBebê
  - [ ] 10.4 Escrever testes de exemplo para geradores de imagem e dados do dia
    - Cache: segunda chamada com mesma chave não chama API externa
    - Fallback: API indisponível → campo omitido, poster gerado mesmo assim
    - _Requisitos: 7.1, 7.2, 7.3, 7.4, 7.5_
  - _Requisitos: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ] 11. Job de geração paralela e Supabase Realtime
  - [ ] 11.1 Implementar `lib/generators/generation-job.ts` com `runGenerationJob(payload: GenerationJobPayload)`: disparar em paralelo (`Promise.all`) as 4 músicas + arte do bebê + dados do dia + poster + arte do nome + PDF; atualizar `Product.status` individualmente; ao concluir tudo, compactar em ZIP, armazenar no bucket `pack-files`, atualizar `Order.status = AWAITING_CHOICE`; deletar foto original do bucket `baby-photos` após geração bem-sucedida da arte
  - [ ] 11.2 Integrar Supabase Realtime: broadcast de `status` no canal `order:{orderId}` a cada mudança de `Order.status` (GENERATING → AWAITING_CHOICE → COMPLETED); usar `postgres_changes` com filtro por `id`
  - [ ] 11.3 Implementar lógica de regeneração em `POST /api/orders/[orderId]/regenerate`: verificar `regenerationCount < 1` (IDOR Guard obrigatório), incrementar contador, disparar novo job apenas para as 4 músicas
  - [ ] 11.4 Escrever testes de propriedade para limite de regeneração
    - **Property 6: Regeneração limitada a 1 vez por pedido**
    - **Valida: Requisitos 6.6, 6.7**
  - [ ] 11.5 Escrever testes de exemplo para job de geração
    - Verificar que foto é deletada após geração bem-sucedida
    - Verificar que Realtime broadcast é emitido em cada mudança de status
    - _Requisitos: 6.1, 6.2, 11.4_
  - _Requisitos: 6.1, 6.2, 6.6, 6.7, 7.7, 11.4_

- [ ] 12. Tela de escolha da canção e upsell de músicas
  - [ ] 12.1 Implementar `GET /api/orders/[orderId]`: IDOR Guard, retornar status + produtos + URLs assinadas frescas do Supabase Storage; renovar URLs expiradas automaticamente
  - [ ] 12.2 Implementar `POST /api/orders/[orderId]/choose`: registrar `chosenVersion` (IDOR Guard), atualizar `Order.chosenVersion`, avançar status para `COMPLETED`
  - [ ] 12.3 Implementar `POST /api/orders/[orderId]/upsell`: validar valor no backend (R$9,90 ou R$19,90), criar novo pagamento MP, atualizar `upsellMusicExtra`/`upsellMusicPack`/`extraMusicVersion` após confirmação via webhook
  - [ ] 12.4 Criar componente `MusicPlayer` (`app/(purchase)/entrega/[orderId]/MusicPlayer.tsx`): player individual por versão com waveform (WaveSurfer.js), letra completa abaixo, botão "Quero essa!", botão "Ouvir novamente"
  - [ ] 12.5 Criar componente `GenerationProgress` com subscription Supabase Realtime no canal `order:{orderId}`; cancelar subscription no cleanup do componente
  - [ ] 12.6 Escrever testes de propriedade para IDOR
    - **Property 4: IDOR — pedido pertence ao usuário**
    - **Valida: Requisitos 8.2, 8.3, 10.4**
  - [ ] 12.7 Escrever testes de exemplo para escolha e upsell
    - Escolha de versão → `chosenVersion` salvo corretamente
    - Upsell com valor manipulado → valor correto cobrado
    - _Requisitos: 6.3, 6.4, 6.5, 6A.1–6A.7_
  - _Requisitos: 6.3, 6.4, 6.5, 6.6, 6.7, 6A.1, 6A.2, 6A.3, 6A.6, 8.1, 8.2, 8.3, 8.7_

- [ ] 13. Tela de entrega, email e drip content
  - [ ] 13.1 Criar componente `DeliveryGallery` (`app/(purchase)/entrega/[orderId]/DeliveryGallery.tsx`): player da canção escolhida (+ extras se upsell), galeria de imagens, botão download ZIP, botões de compartilhamento (WhatsApp, Instagram, Facebook)
  - [ ] 13.2 Implementar `lib/email/templates.ts` com templates Resend: email de entrega (links de download, 30 dias), email modo Presentear (mensagem dedicatória, sem dados de pagamento do comprador), email de notificação "pack pronto"
  - [ ] 13.3 Implementar sequência de drip content em `lib/email/drip.ts`: agendar emails nas semanas 0, 1, 2, 3, 4, 8, 12 e mensalmente até 12 meses; incluir nome do bebê no assunto e corpo; link de opt-out funcional; consentimento explícito antes de incluir na sequência; retry com backoff exponencial (3 tentativas)
  - [ ] 13.4 Implementar endpoint de opt-out: `GET /api/drip/optout?token=...` — cessar todos os emails futuros em até 24h
  - [ ] 13.5 Escrever testes de exemplo para email e drip
    - Modo Presentear: email vai para `recipientEmail`, não `buyerEmail`
    - Email de entrega não inclui dados de pagamento do comprador
    - Sequência de datas de envio correta para pedido criado em data X
    - Opt-out: emails futuros cancelados
    - _Requisitos: 8.4, 8.5, 9.1–9.7, 11.7_
  - _Requisitos: 8.4, 8.5, 8.6, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 11.7_

- [ ] 14. Modo Presentear — Voucher de upload posterior
  - [ ] 14.1 Implementar geração de voucher em `POST /api/orders`: quando `mode = GIFT` e `hasPhoto = false`, gerar `voucherCode` UUID v4 com TTL 90 dias; limitar 5 presentes por email de comprador por dia
  - [ ] 14.2 Implementar `POST /api/voucher/redeem`: verificar que voucher não expirou e não foi resgatado (`voucherRedeemedAt`), aceitar upload de foto, iniciar geração da arte pendente, marcar `voucherRedeemedAt`
  - [ ] 14.3 Escrever testes de propriedade para voucher de uso único
    - **Property 7: Voucher de uso único**
    - **Valida: Requisitos 12.3, 12.5**
  - [ ] 14.4 Escrever testes de exemplo para voucher
    - Voucher já resgatado → erro sem alterar estado
    - Voucher expirado → mensagem de expiração
    - Limite de 5 presentes/email/dia → rejeição
    - _Requisitos: 12.1–12.7_
  - _Requisitos: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

- [ ] 15. Checkpoint — Verificar fluxo completo de compra
  - Garantir que todos os testes passam para o fluxo: formulário → checkout → geração → escolha → entrega → email. Perguntar ao usuário se há dúvidas antes de prosseguir para blog e analytics.

- [ ] 16. Formulário wizard e componentes de UI do fluxo de compra
  - [ ] 16.1 Criar `ModeSelector` (`app/(purchase)/criar/ModeSelector.tsx`): dois cards "Meu bebê" e "Presentear um bebê", persiste modo no estado da sessão
  - [ ] 16.2 Criar `PurchaseWizard` (`app/(purchase)/criar/PurchaseWizard.tsx`) com React Context para estado global do wizard:
    - Step 1: Upload de foto (preview + crop) + campo honeypot oculto via CSS (`position: absolute; left: -9999px`) com `tabIndex={-1}` e `aria-hidden="true"`
    - Step 2: Dados do bebê (campos obrigatórios + opcionais + campos extras no modo Presentear)
    - Step 3: Preferências musicais (6 estilos com preview de áudio 10s, slider binário de tom, campo de palavras especiais) e de arte (4 cards visuais com preview)
  - [ ] 16.3 Criar página de checkout `app/(purchase)/checkout/page.tsx`: resumo do pedido, opções de upsell com preço incremental, integração com Mercado Pago (Pix prioritário)
  - _Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 5.2, 5.3_

- [ ] 17. Blog SEO — Páginas de significado de nomes
  - [ ] 17.1 Criar `app/(marketing)/blog/nomes/significado-do-nome-[nome]/page.tsx` com geração estática (`generateStaticParams`) a partir de `NameEntry`; incluir: resposta direta no 1º parágrafo, origem, personalidade, popularidade, nomes que combinam, famosos, CTA para o produto
  - [ ] 17.2 Adicionar schema JSON-LD `Article` + `FAQ`, meta title (≤60 chars), meta description (≤155 chars), breadcrumbs com schema markup, mínimo 3 links internos por página
  - [ ] 17.3 Implementar `GET /api/blog/[slug]` com rate limit 60/min; aplicar cache adequado
  - _Requisitos: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

- [ ] 18. Blog SEO — Artigos editoriais
  - [ ] 18.1 Criar `app/(marketing)/blog/[slug]/page.tsx` para artigos editoriais: H1 com keyword, resposta direta nos 2–3 primeiros parágrafos, headings H2/H3, CTA contextual, schema JSON-LD (Article/FAQ/HowTo), data de publicação e atualização, alt text em todas as imagens
  - [ ] 18.2 Implementar lazy loading de anúncios AdSense (máx 3 por página: após 2º parágrafo, meio do conteúdo, antes do CTA final) para não impactar Core Web Vitals
  - [ ] 18.3 Adicionar disclaimer automático em artigos com `hasDisclaimer = true` (conteúdo médico/saúde)
  - _Requisitos: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7_

- [ ] 19. Analytics com PostHog
  - [ ] 19.1 Implementar `lib/analytics/posthog.ts` com eventos server-side: `page_view` (landing), `flow_started`, `form_step_completed` (por step), `checkout_started`, `payment_confirmed`, `song_chosen`, `pack_downloaded`, `upsell_clicked`
  - [ ] 19.2 Garantir que nenhum evento inclui dados pessoais identificáveis (nome, email, foto) — usar apenas `orderId` anonimizado e metadados agregados
  - [ ] 19.3 Implementar alerta de log quando tempo de geração excede 5 minutos
  - _Requisitos: 16.1, 16.2, 16.3, 16.4_

- [ ] 20. Upsells adicionais e produtos individuais
  - [ ] 20.1 Implementar lógica de upsells adicionais em `POST /api/orders/[orderId]/upsell`: Pack 3 estilos de arte (R$59,90), Versão animada Stories (R$14,90), Vídeo com música + fotos (R$49,90), Quadro físico A4 (R$89,90), Canvas premium A3 (R$149,90); validar valor no backend
  - [ ] 20.2 Implementar integração com gráfica parceira via API para upsells físicos (quadro/canvas): enviar arte em alta resolução após confirmação de pagamento, enviar email com código de rastreamento quando despachado
  - [ ] 20.3 Implementar venda de itens individuais com preços âncora validados no backend
  - _Requisitos: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6_

- [ ] 21. Reembolso e revogação de links
  - [ ] 21.1 Implementar lógica de reembolso: janela de 7 dias, verificar se pack foi baixado mais de 2x antes de aprovar automaticamente, revogar URLs assinadas do Supabase Storage após reembolso aprovado, atualizar `Order.status = REFUNDED`
  - _Requisitos: 11.5, 11.6_

- [ ] 22. Checkpoint final — Garantir todos os testes passam
  - Executar suite completa de testes (Vitest + fast-check). Verificar checklist de segurança de `docs/SECURITY copy.md` para cada feature implementada. Perguntar ao usuário se há dúvidas antes de considerar a implementação concluída.

## Notas

- Tasks marcadas com `*` são opcionais e podem ser puladas para MVP mais rápido
- Cada task referencia requisitos específicos para rastreabilidade
- **OBRIGATÓRIO**: Consultar context7 para documentação atualizada de Suno v5.5, Google Imagen 3, Supabase, Next.js 16+ e Mercado Pago antes de implementar as tasks correspondentes
- **OBRIGATÓRIO**: Ler `docs/SECURITY copy.md` antes de implementar qualquer endpoint, formulário, upload ou lógica de pagamento
- Testes de propriedade usam fast-check com mínimo 100 iterações (`{ numRuns: 100 }`)
- Tag de referência em cada teste de propriedade: `// Feature: nossobebe-platform, Property N: <texto>`
- Todo conteúdo de UI, emails e blog em português brasileiro
