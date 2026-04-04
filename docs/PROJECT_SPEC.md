# NossoBebê — Especificação do Produto

## Visão geral

NossoBebê é um micro-SaaS brasileiro que vende packs comemorativos digitais personalizados para pais de recém-nascidos. O diferencial é a canção de ninar gerada por IA — uma música única no mundo com o nome do bebê na letra, no estilo que os pais escolhem.

- **Domínio**: nossobebe.com.br
- **Público**: Mães e pais de 25–40 anos, classes B e C, digitalmente ativos
- **Mercado**: ~6.600 nascimentos/dia no Brasil (2,38 milhões em 2024, IBGE)
- **Idioma**: Português brasileiro. Todo o site, UI, emails, blog e conteúdo gerado devem ser em PT-BR

---

## 1. Produtos

### 1.1 Pack Comemorativo (produto principal) — R$39,90

O pack inclui 5 itens entregues digitalmente:

| # | Item | Descrição |
|---|------|-----------|
| 1 | **Canção de Ninar com IA** | Música original gerada por IA (~2 min), com o nome do bebê na letra, no estilo musical escolhido pelos pais. Entregue como MP3 320kbps + vídeo MP4 com visualização para Stories/Reels |
| 2 | **Arte Personalizada com IA** | Retrato artístico do bebê gerado a partir da foto enviada. Estilos: aquarela, ilustração infantil, minimalista, poster retrô. Entregue em PNG 3000x3000px |
| 3 | **O Mundo Quando Você Nasceu** | Poster/infográfico com curiosidades do dia do nascimento: música #1, filme em cartaz, fase da lua, clima na cidade, curiosidade fofa. Tom celebratório, nunca econômico ou negativo. PNG 3000x4000px |
| 4 | **Significado do Nome** | Arte tipográfica com o nome em destaque + origem + significado + pequeno texto poético gerado por IA. PNG 3000x3000px |
| 5 | **Guia Primeiros Meses (bônus)** | Conteúdo baseado em PLR rebrandeado. Cobre cuidados, amamentação, sono, marcos do desenvolvimento. Entregue como PDF estilizado |

### 1.2 Produtos individuais (âncora de preço)

Cada item do pack é vendido separadamente. A soma dos individuais (~R$109,50) torna o pack de R$39,90 a escolha óbvia.

| Produto | Preço individual |
|---------|-----------------|
| Canção de Ninar | R$29,90 |
| Arte Personalizada | R$24,90 |
| O Mundo Quando Nasceu | R$19,90 |
| Significado do Nome | R$14,90 |
| Guia Primeiros Meses | R$19,90 |

### 1.3 Upsells

| Produto | Preço | Descrição |
|---------|-------|-----------|
| +1 música extra | R$9,90 | Segunda música favorita (já gerada, margem 100%) |
| Pack 4 músicas | R$19,90 | Todas as 4 versões geradas (já geradas, margem 100%) |
| Pack 3 estilos de arte | R$59,90 | 3 variações da arte (aquarela + minimalista + ilustração) |
| Vídeo com música + fotos | R$49,90 | Vídeo de 1–2 min com a canção de ninar + slideshow de fotos do bebê |
| Quadro físico A4 moldura | R$89,90 | Impressão print-on-demand via parceiro (Printile/Quadrorama) |
| Canvas premium A3 | R$149,90 | Canvas premium via parceiro |
| Versão animada Stories | R$14,90 | Versão animada da arte para Instagram Stories |

---

## 2. Jornada do usuário (fluxo de compra)

### Etapa 0: Escolha de modo

Primeira tela após o CTA: **"É para o seu bebê ou para presentear?"**

| Modo | Descrição |
|------|-----------|
| **Meu bebê** | Fluxo padrão: pais comprando para o próprio filho |
| **Presentear** | Fluxo presente: amigo, tio, avó, colega comprando como presente |

O modo "Presentear" é um diferencial estratégico enorme. Para cada bebê que nasce, existem 10–20 pessoas no círculo (amigos, familiares, colegas) que querem dar presente. Esse público gasta R$50–200 em presentes genéricos (roupinha, fralda, flores). Uma canção de ninar exclusiva por R$39,90 é o presente mais original e emocionante que poderiam dar — e custa menos que um buquê.

**Diferenças no modo Presentear:**

| Campo | Modo "Meu Bebê" | Modo "Presentear" |
|-------|-----------------|-------------------|
| Step 1 | Upload de foto | Upload de foto (ou "não tenho foto ainda") |
| Step 2 | Dados do bebê | Dados do bebê + nome de quem presenteia |
| Step 2 extra | — | Mensagem dedicatória (textarea, max 300 chars) |
| Step 2 extra | — | Email dos pais (para entrega do presente) |
| Step 2 extra | — | Data de entrega (agora ou agendar para data do nascimento) |
| Entrega | Para o próprio comprador | Email especial para os pais: "Seu amigo [Nome] preparou algo especial para [Bebê]" |
| Drip content | Vai para o comprador | Vai para os pais (com consentimento) |

**Opção "Não tenho foto ainda"**: Para presentes comprados antes do nascimento ou quando o amigo não tem foto. O pack é gerado sem a arte personalizada (ou com arte genérica estilizada) + voucher para os pais fazerem upload depois e gerarem a arte.

**Entrega agendada**: O comprador pode agendar a entrega para a data prevista do parto. O sistema envia no dia programado.

### Etapa 1: Landing Page → CTA

A LP comunica o valor emocional do produto. Hero com vídeo/áudio de exemplo de canção de ninar. Seção de pricing com âncora (individuais vs pack). Social proof. **Dois CTAs**: "Criar o pack do meu bebê" + "Presentear um bebê". Seção específica de "Presente perfeito para recém-nascido" com messaging direcionado (ex: "Mais original que roupinha. Mais emocionante que flores.").

### Etapa 2: Upload + Dados (`/criar`)

Formulário em etapas (wizard):

**Step 1 — Foto do bebê**
- Upload de foto (validação: MIME type + magic bytes, max 10MB, formatos: JPG/PNG/HEIC)
- Preview da foto com crop opcional
- Orientações visuais: "foto com rosto visível, boa iluminação"

**Step 2 — Dados do bebê**
- Nome do bebê (obrigatório, max 50 chars)
- Data de nascimento (date picker, validação: não futuro, max 1 ano atrás)
- Hora de nascimento (time picker, opcional)
- Peso ao nascer (opcional, formato: X,XXX kg)
- Cidade de nascimento (autocomplete com cidades BR)
- Nomes dos pais (opcional, para inclusão na arte)

**Step 3 — Preferências musicais** (`/personalizar`)
- Estilo da canção: MPB, Instrumental, Gospel, Clássico, Lo-fi, Pop suave (radio buttons com preview de 10s de cada estilo)
- Tom: Mais alegre / Mais suave (slider)
- Palavras ou frases especiais para incluir na letra (textarea, max 200 chars, opcional)
- Estilo da arte: Aquarela, Ilustração infantil, Minimalista, Poster retrô (cards visuais com preview)

### Etapa 3: Checkout (`/checkout`)

- Resumo do pedido com preview
- Seleção: Pack completo (R$39,90) vs. produto individual
- Upsells apresentados como "Adicionar por +R$XX"
- Checkout transparente Mercado Pago (cartão, Pix, boleto)
- Pix é prioritário (menor taxa, confirmação instantânea)

### Etapa 4: Escolha da Canção (`/entrega/[orderId]`)

- Tela de "gerando seu pack" com progress bar e animações
- Geração paralela: 4 músicas completas (~2 min cada) + arte + poster + significado
- Tempo alvo: < 60 segundos para gerar as 4 músicas
- Player com waveform + letra completa para cada versão
- Nomes afetivos: "Versão Estrela", "Versão Lua", "Versão Nuvem", "Versão Sol"
- Botão "Quero essa!" abaixo de cada player
- Link discreto "Gerar novas opções" (1 regeneração grátis por pedido, gera 4 novas)
- Upsell na tela de escolha: "Gostou de mais de uma? +1 por R$9,90 ou leve as 4 por R$19,90"

### Etapa 5: Entrega Final

- Entrega na tela: player de áudio para canção escolhida (+ extras se upsell), galeria para imagens, download ZIP
- Email automático com links de download (válidos por 30 dias)
- Botões de compartilhamento: WhatsApp, Instagram, Facebook

### Etapa 6: Pós-venda (drip content)

Sequência de emails semanais personalizados (nome do bebê no assunto e corpo):

| Semana | Email |
|--------|-------|
| 0 | Boas-vindas + links de download + como compartilhar |
| 1 | "Seu bebê tem 1 semana — o que esperar" + dica |
| 2 | "Seu bebê tem 2 semanas" + dica + CTA para upsell arte |
| 3 | Conteúdo + CTA para quadro físico |
| 4 | "1 mês! Parabéns!" + oferta especial mesversário |
| 8 | "2 meses!" + conteúdo |
| 12 | "3 meses!" + oferta pack mesversário |
| ... | Continua até 12 meses |

---

## 3. Landing Page — Estrutura

A LP deve ser otimizada para conversão mobile-first (80%+ do tráfego será mobile).

### Seções (ordem):

1. **Hero**: Headline emocional + subheadline + player de áudio com exemplo de canção + **dois CTAs**: "Criar o pack do meu bebê" e "Presentear um bebê" + selo "Entrega em 2 minutos"
2. **Demonstração**: Exemplos visuais dos 5 itens do pack (carrossel ou grid)
3. **Como funciona**: 4 passos (ícones + texto curto)
4. **Seção Presente**: "O presente mais original para um recém-nascido" — messaging específico para quem quer presentear. Headline: "Mais original que roupinha. Mais emocionante que flores." + CTA "Presentear"
5. **Pricing com âncora**: Tabela mostrando preços individuais vs. pack (R$109,50 → R$39,90)
6. **Social proof**: Depoimentos (incluir depoimentos de quem recebeu como presente), contador "X bebês já receberam sua canção"
7. **FAQ**: Accordion com perguntas frequentes (schema markup FAQ) — incluir FAQ sobre presentes
8. **CTA final**: Repetição dos dois CTAs
8. **Footer**: Links legais, redes sociais, contato

### Design:
- Paleta: Crafts (#E9E6DA), Fairy-tale (#E2A18A), Crib (#896450), Hamper (#DDB068), Rhymes (#BEC6AB), Musical (#8BA4B5) — ver BRAND.md
- Tipografia: Playfair Display (headings) + Inter (corpo) + Caveat (decorativo)
- Tom visual: Acolhedor, orgânico, terroso, premium mas acessível
- Fundo creme (Crafts), nunca branco puro. Texto em Crib, nunca preto puro
- Sem excesso de elementos — clean e respirado

---

## 4. Blog SEO

### Objetivo duplo
1. Gerar tráfego orgânico massivo (Google + IAs como Perplexity/ChatGPT)
2. Monetizar com AdSense + funil para o produto

### Categorias e volume

| Categoria | Tipo | Volume alvo |
|-----------|------|-------------|
| Significado de nomes | Programático | 1.000+ páginas |
| Desenvolvimento semana a semana | Editorial | 52 artigos |
| Desenvolvimento mês a mês | Editorial | 24 artigos (0–24 meses) |
| Dúvidas comuns | Editorial | 200+ artigos |
| Guias práticos | Editorial | 50+ artigos |
| Datas comemorativas | Sazonal | 20+ artigos |

### Página de nome (template programático)

URL: `/blog/nomes/significado-do-nome-[nome]`

Estrutura:
```
H1: Significado do nome [Nome]
→ Resposta direta em 2 frases (featured snippet)

H2: Origem do nome [Nome]
→ 2-3 parágrafos

H2: Personalidade de quem se chama [Nome]
→ 2-3 parágrafos (tom leve e positivo)

H2: Popularidade do nome [Nome] no Brasil
→ Dados do IBGE se disponíveis

H2: Nomes que combinam com [Nome]
→ Lista de combinações populares

H2: Famosos com o nome [Nome]
→ 3-5 exemplos

H2: Eternize o nome [Nome] (CTA)
→ "Que tal uma canção de ninar exclusiva com o nome [Nome]?"
→ CTA para o produto

Schema: Article + FAQ (2-3 perguntas frequentes sobre o nome)
```

### Página editorial (template)

URL: `/blog/[categoria]/[slug]`

Estrutura:
```
H1: [Título otimizado para keyword]
→ Resposta direta em 2-3 frases (featured snippet / IA)

[Conteúdo com H2s e H3s hierárquicos]

[CTA contextual para o produto — adaptado ao tema do artigo]

Schema: Article + FAQ ou HowTo (conforme conteúdo)
```

### Regras SEO para todo artigo

- Title tag: max 60 chars, keyword no início
- Meta description: max 155 chars, com CTA emocional
- URL: limpa, descritiva, sem stop words
- H1 único, keyword principal
- Primeiro parágrafo responde a pergunta diretamente
- Alt text em todas as imagens
- Links internos: 3-5 por artigo (artigos relacionados + produto)
- Schema JSON-LD no head
- Breadcrumbs com schema
- Tempo de leitura estimado
- Data de publicação e atualização visíveis

### AdSense

- Posicionamento: 1 anúncio após o 2º parágrafo, 1 no meio, 1 antes do CTA final
- Nunca mais de 3 anúncios por página
- Sem anúncios na LP ou no fluxo de compra (só no blog)
- Lazy load nos anúncios para não impactar Core Web Vitals

---

## 5. Integrações de IA

### 5.1 Geração de música

**Provedor principal: Google Lyria 3 Pro (Vertex AI)**
- Gera músicas de até 3 min
- API oficial documentada
- Custo: ~US$0,08/música

**Fallback: Suno v5.5 (via wrapper)**
- Melhor qualidade em letras em português
- Via sunoapi.org ou similar
- Custo: ~US$0,02–0,05/música

**Estratégia de 4 músicas completas + escolha:**

O sistema gera 4 músicas completas (~2 min cada) com letras e arranjos diferentes. O usuário ouve as 4 inteiras, lê as letras, e escolhe a favorita. Previews curtos não são suficientes — a letra com o nome do bebê precisa ser ouvida e lida por completo.

| Etapa | Descrição | Custo |
|-------|-----------|-------|
| 4 músicas completas (~2min cada) | Letras diferentes + variações de arranjo | ~R$0,40–R$1,80 |
| Escolha do usuário | Player com waveform + letra, nomes afetivos ("Estrela", "Lua", "Nuvem", "Sol") | — |
| Regeneração (1x grátis) | Se nenhuma agradar, gera 4 novas | ~R$0,40–R$1,80 |
| Upsell | +1 música extra R$9,90 / Pack 4 músicas R$19,90 (margem 100%, já geradas) | — |

**Prompt template para canção de ninar:**
```
Crie uma canção de ninar em português brasileiro, estilo [ESTILO].
A música deve ser suave e acolhedora, com duração de aproximadamente 2 minutos.
O nome do bebê é [NOME] e deve aparecer na letra de forma natural, pelo menos 3 vezes.
[SE HOUVER] Inclua referência a: [PALAVRAS_ESPECIAIS]
[SE HOUVER] O significado do nome é [SIGNIFICADO] — faça uma referência sutil.
Tom: [MAIS_ALEGRE | MAIS_SUAVE]
A letra deve ser poética mas simples, algo que os pais consigam cantarolar.
Não use palavras difíceis ou abstratas demais.
```

### 5.2 Geração de imagem

**Provedor: OpenAI GPT-Image-1**
- Custo: ~US$0,04–0,17/imagem (depende da qualidade)

**Para a arte do bebê:**
```
Crie um retrato artístico estilo [ESTILO] de um bebê recém-nascido.
Use a foto fornecida como referência para as feições.
Estilo: [aquarela suave | ilustração infantil colorida | minimalista com linhas finas | poster retrô vintage]
Cores: paleta suave e acolhedora.
O resultado deve ser adequado para imprimir em alta qualidade e emoldurar.
Não inclua texto na imagem.
```

**Para o poster "O Mundo Quando Nasceu":**
```
Crie um poster infográfico delicado e celebratório com layout vertical.
Título: "O Mundo Quando [NOME] Nasceu"
Data: [DATA]
Inclua os seguintes dados dispostos de forma visual e elegante:
- Música #1: [MUSICA]
- Filme em cartaz: [FILME]
- Fase da lua: [FASE] (com ícone)
- Clima em [CIDADE]: [CLIMA]
- [CURIOSIDADE_FOFA]
Estilo: clean, moderno, cores suaves (rosa/azul bebê/branco).
Tipografia elegante. Adequado para impressão em alta qualidade.
```

### 5.3 Dados do dia do nascimento

APIs a integrar:

| Dado | Fonte | Endpoint |
|------|-------|----------|
| Música #1 Brasil | Spotify Charts API | Charts regionais por data |
| Clima na cidade | OpenWeather History API | Dados históricos por cidade/data |
| Fase da lua | API de fases lunares (cálculo local possível) | Por data |
| Filme em cartaz | TMDB API (The Movie Database) | Filmes em cartaz por data/região |
| Curiosidade fofa | Banco de dados próprio + geração IA | Curadoria manual + fallback IA |

**Importante**: cache agressivo. Se 3 bebês nascem no mesmo dia na mesma cidade, os dados do dia são idênticos. Cache por data+cidade com TTL de 24h.

---

## 6. Banco de dados (Prisma schema)

Entidades principais:

```
Order (pedido)
├── id, status, amount, paymentMethod, paymentId
├── mode: SELF | GIFT
├── babyName, birthDate, birthTime, birthWeight, birthCity
├── parentNames, musicStyle, musicTone, specialWords
├── artStyle, photoUrl
├── buyerEmail (email de quem comprou)
├── buyerName (nome de quem comprou — relevante em modo GIFT)
├── recipientEmail (email dos pais — em GIFT, diferente do buyer)
├── giftMessage (mensagem dedicatória, max 300 chars — só GIFT)
├── scheduledDeliveryAt (entrega agendada — só GIFT, nullable)
├── hasPhoto (boolean — em GIFT pode ser false, com voucher para upload posterior)
├── voucherCode (código para pais fazerem upload da foto depois — só GIFT sem foto)
├── createdAt, updatedAt, deliveredAt
└── products: Product[] (relação muitos-para-muitos)

Product (produto gerado)
├── id, orderId, type (MUSIC | ART | POSTER | NAME | GUIDE)
├── fileUrl, thumbnailUrl
├── metadata (JSON: dados específicos do tipo)
├── status (PENDING | GENERATING | DONE | FAILED)
└── createdAt

DripEmail (emails da sequência)
├── id, orderId, weekNumber, sentAt, status
└── templateId

BlogPost (posts do blog)
├── id, slug, title, description, category
├── content (MDX ou HTML)
├── publishedAt, updatedAt
├── schemaType (ARTICLE | FAQ | HOWTO)
└── seoScore

NameEntry (banco de nomes)
├── id, name, origin, meaning, personality
├── popularity, famousPeople
├── blogPostId (relação com post do blog)
└── variations
```

---

## 7. Estratégia de validação (fases)

### Fase 1: Manual (Semanas 1–6)
- Landing page simples + formulário + Mercado Pago
- Atendimento via WhatsApp para preferências musicais
- Geração manual (você monta o prompt, gera, ajusta)
- Entrega em até 24h
- Preço: R$59,90–R$79,90
- Meta: 5–10 vendas/dia
- **O que construir**: LP + checkout + entrega por email. Geração é manual.

### Fase 2: Semi-automático (Semanas 7–12)
- Formulário inteligente substitui WhatsApp
- Geração automática via APIs
- Entrega em < 5 min
- Preço: R$39,90–R$49,90
- Blog SEO: primeiros 100 artigos + AdSense
- **O que construir**: Fluxo completo automatizado + blog + drip emails

### Fase 3: Escala (Mês 4+)
- Agente de IA para personalização
- Upsell físico (print-on-demand)
- Parcerias com maternidades
- Blog: 500+ artigos
- Meta: 70+ vendas/dia

---

## 8. Métricas a trackear

| Métrica | Ferramenta | Meta |
|---------|------------|------|
| Conversão LP → Checkout | PostHog | > 5% |
| Conversão Checkout → Pagamento | PostHog | > 60% |
| Tempo de geração do pack | Logs internos | < 2 min |
| Taxa de upsell (quadro físico) | PostHog | > 15% |
| NPS / Satisfação | Email pós-entrega | > 70 |
| Pageviews blog | PostHog + Search Console | Crescimento mensal |
| RPM AdSense | AdSense | R$15–40 |
| CAC (tráfego pago) | Meta Ads | < R$15 |
| LTV (pack + upsells + referral) | Interno | > R$60 |
