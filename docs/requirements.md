# Documento de Requisitos — NossoBebê Platform

## Introdução

O NossoBebê é um micro-SaaS brasileiro que vende packs comemorativos digitais personalizados para pais de recém-nascidos. O produto principal é um pack de R$39,90 composto por cinco itens gerados por IA: canção de ninar personalizada (MP3 + MP4), arte do bebê, poster "O Mundo Quando Você Nasceu", arte do significado do nome e guia dos primeiros meses (PDF). O sistema opera em dois modos: "Meu Bebê" (pais comprando para o próprio filho) e "Presentear" (terceiros comprando como presente). A canção de ninar é o diferencial central: o sistema gera 4 músicas completas (~2 min cada) com letras e arranjos diferentes, o Comprador ouve todas, lê as letras e escolhe a favorita — porque a letra com o nome do bebê precisa ser ouvida e lida por completo para ser avaliada. Todo o conteúdo, UI, emails e blog são em português brasileiro.

---

## Glossário

- **Sistema**: A plataforma NossoBebê como um todo (frontend Next.js + API Routes + banco de dados)
- **Comprador**: Pessoa que realiza o pagamento (pode ser o próprio pai/mãe ou um presenteador)
- **Destinatário**: Pais do bebê que recebem o pack (no modo Presentear, diferente do Comprador)
- **Pack**: Conjunto dos cinco itens digitais entregues após o pagamento confirmado
- **Canção_Completa**: Canção de ninar completa (~2 min) gerada pelo Gerador_de_Música com letra e arranjo únicos
- **Versão_Estrela**: Canção_Completa com arranjo acústico/orgânico e letra mais poética
- **Versão_Lua**: Canção_Completa com arranjo com mais elementos (teclado, cordas leves) e letra mais narrativa
- **Versão_Nuvem**: Canção_Completa com variação de andamento e letra com mais repetição do nome do bebê
- **Versão_Sol**: Canção_Completa com tom mais alegre/animado e letra mais brincalhona
- **Canção_Escolhida**: A Canção_Completa selecionada pelo Comprador como favorita, incluída no Pack
- **Formulário**: Wizard de múltiplos passos em `/criar` onde o Comprador insere dados do bebê e preferências
- **Checkout**: Tela de pagamento em `/checkout` integrada ao Mercado Pago
- **Tela_de_Escolha**: Página em `/entrega/[orderId]` onde o Comprador ouve as 4 Canções_Completas e escolhe a favorita
- **Tela_de_Entrega**: Seção da mesma página após a escolha, onde o Comprador acessa o Pack completo
- **Pedido**: Registro no banco de dados representando uma compra, com status e itens associados
- **Voucher**: Código UUID gerado no modo Presentear quando não há foto do bebê, permitindo upload posterior
- **Drip_Content**: Sequência de emails semanais personalizados enviados após a compra
- **Gerador_de_Música**: Serviço de IA (Google Lyria 3 Pro como principal, Suno como fallback) que produz as canções
- **Gerador_de_Imagem**: Serviço OpenAI GPT-Image-1 que produz as artes visuais
- **Storage**: Cloudflare R2, onde os arquivos gerados são armazenados com URLs assinadas
- **Validator**: Módulo de validação de inputs usando Zod em todos os endpoints da API
- **Rate_Limiter**: Módulo de rate limiting usando @upstash/ratelimit aplicado em endpoints públicos
- **IDOR_Guard**: Verificação de propriedade de recurso por usuário autenticado em todo endpoint que recebe ID
- **Blog**: Seção de conteúdo SEO em `/blog` com categorias programáticas e editoriais
- **Modo_Meu_Bebê**: Fluxo de compra onde o Comprador é o próprio pai ou mãe do bebê
- **Modo_Presentear**: Fluxo de compra onde o Comprador é um terceiro presenteando os pais
- **Upsell**: Produto adicional oferecido durante ou após o checkout principal

---

## Requisitos

### Requisito 1: Escolha de Modo de Compra

**User Story:** Como visitante da landing page, quero escolher entre comprar para o meu próprio bebê ou presentear outra família, para que o fluxo de compra seja adequado à minha situação.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir na primeira tela do fluxo de compra duas opções claramente distintas: "Meu bebê" e "Presentear um bebê".
2. WHEN o Comprador seleciona "Meu bebê", THE Sistema SHALL iniciar o fluxo Modo_Meu_Bebê com upload de foto obrigatório.
3. WHEN o Comprador seleciona "Presentear um bebê", THE Sistema SHALL iniciar o fluxo Modo_Presentear com upload de foto opcional.
4. WHEN o Comprador está no Modo_Presentear e seleciona "Não tenho foto ainda", THE Sistema SHALL prosseguir o fluxo sem foto e gerar um Voucher para upload posterior pelos pais.
5. THE Sistema SHALL preservar o modo selecionado durante toda a sessão de compra até a conclusão do Pedido.

---

### Requisito 2: Upload e Validação de Foto do Bebê

**User Story:** Como Comprador, quero fazer upload da foto do bebê de forma segura, para que a arte personalizada seja gerada corretamente.

#### Critérios de Aceitação

1. WHEN o Comprador submete um arquivo de foto, THE Validator SHALL verificar o tamanho máximo de 10MB antes de qualquer processamento.
2. WHEN o Comprador submete um arquivo de foto, THE Validator SHALL verificar os magic bytes do arquivo para confirmar que o MIME type real é image/jpeg, image/png, image/heic ou image/heif.
3. WHEN o Validator detecta um arquivo com MIME type inválido ou magic bytes inconsistentes, THE Sistema SHALL retornar erro HTTP 400 com mensagem descritiva sem revelar detalhes internos.
4. WHEN a foto passa na validação de tipo, THE Sistema SHALL processar a imagem com sharp para verificar que width e height são maiores que zero e menores que 8000 pixels cada dimensão.
5. WHEN a foto passa em todas as validações, THE Sistema SHALL remover os metadados EXIF da foto (incluindo dados de geolocalização GPS) antes de armazenar no Storage.
6. WHEN a arte personalizada do bebê é gerada com sucesso, THE Sistema SHALL deletar a foto original do Storage em até 24 horas após a geração.
7. THE Sistema SHALL renomear o arquivo de foto com um UUID v4 antes de armazenar, nunca usando o nome original do arquivo.
8. WHEN o Comprador faz upload de foto, THE Rate_Limiter SHALL limitar a 5 requisições por IP por minuto para o endpoint `POST /api/upload`.

---

### Requisito 3: Formulário de Dados do Bebê

**User Story:** Como Comprador, quero preencher os dados do bebê em um formulário guiado, para que o pack seja personalizado com as informações corretas.

#### Critérios de Aceitação

1. THE Formulário SHALL coletar os seguintes campos obrigatórios: nome do bebê (1–50 caracteres), data de nascimento (formato ISO date, não futura, máximo 1 ano no passado) e cidade de nascimento (2–100 caracteres).
2. THE Formulário SHALL coletar os seguintes campos opcionais: hora de nascimento (formato HH:MM), peso ao nascer (máximo 10 caracteres), nomes dos pais (máximo 100 caracteres).
3. WHEN o Comprador está no Modo_Presentear, THE Formulário SHALL coletar adicionalmente: nome de quem presenteia (máximo 100 caracteres), mensagem dedicatória (máximo 300 caracteres), email dos pais (formato email válido, máximo 254 caracteres) e opção de data de entrega agendada.
4. WHEN o Comprador define uma data de entrega agendada no Modo_Presentear, THE Validator SHALL rejeitar datas superiores a 9 meses no futuro a partir da data atual.
5. WHEN o Comprador submete o Formulário, THE Validator SHALL validar todos os campos com Zod antes de persistir qualquer dado no banco de dados.
6. IF o Validator detecta qualquer campo fora das restrições definidas, THEN THE Sistema SHALL retornar HTTP 400 com os erros específicos por campo sem expor detalhes de implementação interna.
7. THE Formulário SHALL incluir um campo honeypot oculto (posicionado fora da tela via CSS, sem tabIndex) que, se preenchido, faz o Sistema retornar HTTP 200 com resposta fake sem processar o pedido.

---

### Requisito 4: Preferências Musicais e de Arte

**User Story:** Como Comprador, quero escolher o estilo musical e o estilo da arte, para que o pack reflita o gosto da família.

#### Critérios de Aceitação

1. THE Formulário SHALL oferecer seis opções de estilo musical: MPB, Instrumental, Gospel, Clássico, Lo-fi e Pop suave — representadas como radio buttons com preview de áudio de 10 segundos cada.
2. THE Formulário SHALL oferecer dois tons musicais: "Mais alegre" e "Mais suave" — representados como slider binário.
3. THE Formulário SHALL oferecer um campo de texto opcional para palavras ou frases especiais a incluir na letra (máximo 200 caracteres).
4. THE Formulário SHALL oferecer quatro opções de estilo de arte: Aquarela, Ilustração infantil, Minimalista e Poster retrô — representadas como cards visuais com preview de imagem.
5. WHEN o Comprador submete as preferências, THE Validator SHALL aceitar apenas os valores enumerados para estilo musical (`mpb`, `instrumental`, `gospel`, `classico`, `lofi`, `pop`) e estilo de arte (`aquarela`, `ilustracao`, `minimalista`, `retro`).
6. IF o Validator recebe um valor de estilo fora dos enumerados, THEN THE Sistema SHALL retornar HTTP 400 sem processar o pedido.

---

### Requisito 5: Checkout e Pagamento

**User Story:** Como Comprador, quero realizar o pagamento de forma segura e conveniente, para que meu pedido seja confirmado e o pack seja gerado.

#### Critérios de Aceitação

1. THE Sistema SHALL integrar com o Mercado Pago para processar pagamentos via Pix (prioritário), cartão de crédito e boleto bancário.
2. WHEN o Comprador acessa o checkout, THE Sistema SHALL exibir o resumo do pedido com os itens selecionados e o valor total antes de solicitar dados de pagamento.
3. THE Sistema SHALL oferecer upsells no checkout como opções adicionais com preço incremental claramente exibido.
4. WHEN o Mercado Pago confirma o pagamento via webhook, THE Sistema SHALL verificar a assinatura do webhook antes de processar qualquer ação.
5. WHEN o Sistema recebe um webhook de pagamento confirmado, THE Sistema SHALL usar uma idempotency key baseada no ID do pagamento do Mercado Pago para garantir que o Pedido seja processado exatamente uma vez.
6. WHEN o Sistema recebe um webhook de pagamento confirmado para um Pedido já processado, THE Sistema SHALL retornar HTTP 200 sem reprocessar o Pedido.
7. THE Sistema SHALL iniciar a geração do Pack somente após a confirmação de pagamento via webhook, nunca antes.
8. WHEN o Comprador acessa o checkout, THE Rate_Limiter SHALL limitar a 10 requisições por IP por minuto para o endpoint `POST /api/checkout`.

---

### Requisito 6: Geração de 4 Canções Completas para Escolha

**User Story:** Como Comprador, quero ouvir 4 canções de ninar completas com letras diferentes antes de escolher, para que eu possa avaliar a letra inteira com o nome do meu bebê e escolher com total confiança.

#### Critérios de Aceitação

1. WHEN o pagamento é confirmado, THE Gerador_de_Música SHALL gerar em paralelo 4 Canções_Completas de aproximadamente 2 minutos cada, com letras e arranjos distintos: Versão_Estrela (arranjo acústico/orgânico, letra poética), Versão_Lua (arranjo com mais elementos musicais, letra narrativa), Versão_Nuvem (variação de andamento, letra com mais repetição do nome do bebê) e Versão_Sol (tom alegre/animado, letra brincalhona).
2. THE Sistema SHALL concluir a geração paralela das 4 Canções_Completas em menos de 60 segundos a partir da confirmação do pagamento.
3. THE Sistema SHALL exibir na Tela_de_Escolha cada Canção_Completa em player individual com visualização de waveform e a letra completa exibida abaixo do player, identificadas pelos nomes afetivos "Versão Estrela", "Versão Lua", "Versão Nuvem" e "Versão Sol".
4. THE Sistema SHALL exibir na Tela_de_Escolha o texto "Ouça cada canção, leia a letra, e escolha a que mais toca seu coração." acima dos players.
5. WHEN o Comprador clica em "Quero essa!" abaixo de uma Canção_Completa, THE Sistema SHALL registrar aquela versão como Canção_Escolhida e prosseguir para a Tela_de_Entrega.
6. THE Sistema SHALL permitir ao Comprador regenerar as 4 Canções_Completas exatamente 1 vez por Pedido, sem custo adicional, gerando 4 novas canções com letras e arranjos diferentes.
7. WHEN o Comprador solicita regeneração e o limite de 1 regeneração já foi atingido, THE Sistema SHALL exibir mensagem informando que o limite foi atingido e oferecer link para suporte.
8. THE Gerador_de_Música SHALL usar Google Lyria 3 Pro como provedor principal e Suno como fallback automático em caso de falha ou indisponibilidade de qualquer geração individual.
9. IF o Gerador_de_Música falha em ambos os provedores após 3 tentativas para qualquer uma das 4 canções, THEN THE Sistema SHALL notificar o Comprador por email e registrar o erro para resolução manual.
10. WHEN o Comprador acessa a Tela_de_Escolha, THE Rate_Limiter SHALL limitar a 3 requisições por IP por minuto para endpoints `POST /api/generate/*`.

---

### Requisito 6A: Upsell de Músicas Extras na Tela de Escolha

**User Story:** Como Comprador que gostou de mais de uma canção, quero poder adquirir versões adicionais além da favorita, para que eu tenha mais de uma canção única do meu bebê.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir na Tela_de_Escolha, abaixo dos players das 4 Canções_Completas, o upsell inline com o texto "Gostou de mais de uma? Leve todas — cada uma é única e nunca mais será gerada." e as opções "+1 música extra por R$9,90" e "Pack 4 músicas por R$19,90".
2. WHEN o Comprador seleciona "+1 música extra" por R$9,90, THE Sistema SHALL permitir que o Comprador indique qual das Canções_Completas não escolhidas deseja como segunda favorita antes de processar o pagamento adicional.
3. WHEN o Comprador seleciona "Pack 4 músicas" por R$19,90, THE Sistema SHALL incluir todas as 4 Canções_Completas geradas na entrega, sem necessidade de seleção adicional.
4. THE Sistema SHALL processar o pagamento dos upsells de músicas via Mercado Pago com o mesmo fluxo de confirmação por webhook do pagamento principal.
5. WHEN o pagamento do upsell de músicas é confirmado, THE Sistema SHALL incluir as Canções_Completas adicionais na Tela_de_Entrega e no email de download, sem gerar novas músicas (as músicas já foram geradas).
6. THE Sistema SHALL validar no backend o valor do upsell de músicas (R$9,90 para +1 ou R$19,90 para pack 4), nunca confiando no valor enviado pelo cliente.
7. WHEN o Comprador já escolheu a Canção_Escolhida e acessa a Tela_de_Entrega, THE Sistema SHALL exibir o upsell de músicas extras caso o Comprador ainda não o tenha adquirido, com o mesmo texto e opções da Tela_de_Escolha.

---

### Requisito 7: Geração dos Itens Visuais do Pack

**User Story:** Como Comprador, quero receber arte personalizada de alta qualidade, para que os itens do pack sejam únicos e adequados para impressão.

#### Critérios de Aceitação

1. WHEN o pagamento é confirmado, THE Gerador_de_Imagem SHALL gerar a arte personalizada do bebê no estilo escolhido, com resolução de 3000x3000 pixels, em formato PNG.
2. WHEN o pagamento é confirmado, THE Sistema SHALL buscar os dados do dia do nascimento nas APIs externas (Spotify Charts para música #1, OpenWeather History para clima, TMDB para filme em cartaz, API lunar para fase da lua) e gerar o poster "O Mundo Quando Você Nasceu" em PNG 3000x4000 pixels.
3. WHEN o pagamento é confirmado, THE Sistema SHALL gerar a arte do significado do nome com texto poético gerado por IA, em PNG 3000x3000 pixels.
4. THE Sistema SHALL armazenar os dados do dia do nascimento em cache por data e cidade com TTL de 24 horas para evitar chamadas redundantes às APIs externas.
5. IF uma API externa de dados do dia estiver indisponível, THEN THE Sistema SHALL usar dados de fallback pré-definidos para aquele campo específico sem bloquear a geração do poster.
6. THE Sistema SHALL gerar o PDF do Guia dos Primeiros Meses a partir do conteúdo PLR rebrandeado com a identidade visual NossoBebê.
7. WHEN todos os itens do Pack são gerados com sucesso, THE Sistema SHALL compactar os arquivos em um ZIP e armazenar no Storage com URL assinada de TTL de 30 dias.

---

### Requisito 8: Tela de Entrega e Download

**User Story:** Como Comprador, quero acessar e baixar todos os itens do pack de forma fácil, para que eu possa guardar e compartilhar as memórias do meu bebê.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir na Tela_de_Entrega: player de áudio para a Canção_Escolhida (e canções adicionais se upsell adquirido), galeria com as imagens geradas e botão de download do ZIP completo.
2. WHEN o Comprador acessa a Tela_de_Entrega, THE IDOR_Guard SHALL verificar que o orderId da URL pertence ao email da sessão autenticada antes de exibir qualquer conteúdo.
3. IF o IDOR_Guard detecta que o orderId não pertence ao usuário autenticado, THEN THE Sistema SHALL retornar HTTP 404 sem revelar a existência do recurso.
4. THE Sistema SHALL enviar email automático ao Destinatário com links de download válidos por 30 dias após a entrega do Pack.
5. WHEN o Comprador está no Modo_Presentear, THE Sistema SHALL enviar email especial aos pais com a mensagem dedicatória do Comprador e os links de download, sem incluir dados de pagamento do Comprador.
6. THE Sistema SHALL exibir botões de compartilhamento para WhatsApp, Instagram e Facebook na Tela_de_Entrega.
7. WHEN as URLs assinadas do Storage expiram, THE Sistema SHALL renovar as URLs sob demanda quando o Destinatário acessa a Tela_de_Entrega.

---

### Requisito 9: Drip Content por Email

**User Story:** Como pai ou mãe que comprou o pack, quero receber emails semanais personalizados com dicas sobre o desenvolvimento do meu bebê, para que eu me sinta acompanhado nos primeiros meses.

#### Critérios de Aceitação

1. THE Sistema SHALL iniciar a sequência de Drip Content imediatamente após a entrega do Pack, enviando o email de boas-vindas (semana 0) com os links de download e instruções de compartilhamento.
2. THE Sistema SHALL enviar emails nas semanas 1, 2, 3, 4, 8, 12 e mensalmente até 12 meses, com conteúdo personalizado incluindo o nome do bebê no assunto e no corpo do email.
3. WHEN o Destinatário está no Modo_Presentear, THE Sistema SHALL enviar o Drip Content para o email dos pais (Destinatário), não para o email do Comprador.
4. THE Sistema SHALL incluir em cada email de Drip Content um link de descadastro (opt-out) funcional que remove o Destinatário da sequência imediatamente.
5. WHEN o Destinatário clica no link de opt-out, THE Sistema SHALL cessar todos os emails futuros de Drip Content para aquele Pedido em até 24 horas.
6. THE Sistema SHALL obter consentimento explícito do Destinatário para recebimento de emails de marketing antes de incluí-lo na sequência de Drip Content.
7. IF o envio de email falha, THEN THE Sistema SHALL tentar reenvio com backoff exponencial por até 3 tentativas antes de registrar falha permanente.

---

### Requisito 10: Segurança — Validação e Rate Limiting

**User Story:** Como operador da plataforma, quero que todos os endpoints sejam protegidos contra abuso e entradas maliciosas, para que a plataforma seja segura e confiável.

#### Critérios de Aceitação

1. THE Validator SHALL aplicar validação Zod em todos os endpoints da API antes de qualquer processamento de dados ou acesso ao banco de dados.
2. THE Rate_Limiter SHALL aplicar os seguintes limites usando @upstash/ratelimit: `POST /api/upload` — 5 req/min por IP; `POST /api/generate/*` — 3 req/min por IP; `POST /api/checkout` — 10 req/min por IP; `GET /api/blog/*` — 60 req/min por IP; `POST /api/webhooks/*` — 30 req/min por IP.
3. WHEN o Rate_Limiter detecta excesso de requisições, THE Sistema SHALL retornar HTTP 429 com header `Retry-After` indicando o tempo de espera em segundos.
4. THE IDOR_Guard SHALL verificar em todo endpoint que recebe um ID de Pedido ou recurso que o recurso pertence ao usuário autenticado antes de retornar qualquer dado.
5. THE Sistema SHALL sanitizar todo input de texto livre antes de interpolar em prompts de IA para prevenir prompt injection.
6. THE Sistema SHALL configurar os seguintes headers de segurança HTTP em todas as respostas: `Strict-Transport-Security`, `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: origin-when-cross-origin`, `Permissions-Policy: camera=(), microphone=(), geolocation=()` e `Content-Security-Policy` restritivo.
7. THE Sistema SHALL implementar endpoints decoy (`/api/admin/users`, `/api/v2/export`) que retornam dados fictícios e registram o IP do acesso para monitoramento de segurança.

---

### Requisito 11: Segurança — Operações Críticas e Dados Sensíveis

**User Story:** Como operador da plataforma, quero que operações financeiras e dados sensíveis sejam tratados com isolamento e proteção adequados, para que não haja inconsistências ou vazamentos de dados.

#### Critérios de Aceitação

1. WHEN o Sistema processa a confirmação de pagamento, THE Sistema SHALL executar a atualização de status do Pedido dentro de uma transação Prisma com nível de isolamento `Serializable` para prevenir race conditions.
2. WHEN o Sistema recebe múltiplos webhooks simultâneos para o mesmo Pedido, THE Sistema SHALL processar apenas o primeiro e ignorar os demais usando a idempotency key do pagamento.
3. THE Sistema SHALL nunca armazenar dados de cartão de crédito — todo processamento de cartão é delegado ao Mercado Pago.
4. THE Sistema SHALL deletar a foto original do bebê do Storage após a geração bem-sucedida da arte, em até 24 horas.
5. THE Sistema SHALL armazenar URLs de download com TTL de 30 dias e revogar os links de download após reembolso aprovado.
6. WHEN um reembolso é solicitado dentro de 7 dias após a compra, THE Sistema SHALL verificar se o Pack foi baixado mais de 2 vezes antes de aprovar o reembolso automaticamente.
7. THE Sistema SHALL nunca incluir dados de pagamento do Comprador em emails enviados ao Destinatário no Modo_Presentear.

---

### Requisito 12: Modo Presentear — Voucher de Upload Posterior

**User Story:** Como presenteador que não tem a foto do bebê no momento da compra, quero receber um voucher para que os pais possam fazer o upload da foto depois e receber a arte personalizada.

#### Critérios de Aceitação

1. WHEN o Comprador no Modo_Presentear seleciona "Não tenho foto ainda", THE Sistema SHALL gerar um Voucher com código UUID v4 e TTL de 90 dias.
2. THE Sistema SHALL enviar o Voucher por email aos pais (Destinatário) com instruções claras de como fazer o upload da foto.
3. WHEN os pais acessam o link do Voucher, THE Sistema SHALL verificar que o Voucher não expirou e não foi resgatado anteriormente.
4. WHEN os pais fazem upload da foto via Voucher, THE Sistema SHALL iniciar a geração da arte personalizada e entregar o item pendente do Pack.
5. IF o Voucher já foi resgatado anteriormente, THEN THE Sistema SHALL retornar mensagem informando que o Voucher já foi utilizado, sem processar novo upload.
6. IF o Voucher expirou (mais de 90 dias), THEN THE Sistema SHALL retornar mensagem informando a expiração e oferecer link para contato com suporte.
7. THE Sistema SHALL limitar a 5 presentes por email de Comprador por dia para prevenir abuso.

---

### Requisito 13: Blog SEO — Páginas de Significado de Nomes

**User Story:** Como visitante que pesquisa o significado de um nome no Google, quero encontrar uma página completa e útil sobre o nome, para que eu possa tomar decisões informadas e descobrir o produto NossoBebê.

#### Critérios de Aceitação

1. THE Blog SHALL gerar páginas programáticas para cada nome no banco de dados com URL no formato `/blog/nomes/significado-do-nome-[nome]`.
2. THE Blog SHALL incluir em cada página de nome: resposta direta no primeiro parágrafo (para featured snippet), origem do nome, personalidade associada, popularidade no Brasil, nomes que combinam, famosos com o nome e CTA para o produto.
3. THE Blog SHALL incluir schema JSON-LD do tipo `Article` e `FAQ` em cada página de nome.
4. THE Blog SHALL incluir meta title com máximo de 60 caracteres e meta description com máximo de 155 caracteres em cada página.
5. THE Blog SHALL incluir breadcrumbs com schema markup em todas as páginas.
6. THE Blog SHALL incluir no mínimo 3 links internos por artigo apontando para artigos relacionados ou para o produto.
7. WHEN um visitante acessa uma página de nome, THE Blog SHALL exibir CTA contextual para criação de canção de ninar personalizada com aquele nome.

---

### Requisito 14: Blog SEO — Artigos Editoriais

**User Story:** Como pai ou mãe de primeira viagem, quero encontrar artigos úteis sobre desenvolvimento do bebê, para que eu me sinta preparado e conheça o produto NossoBebê.

#### Critérios de Aceitação

1. THE Blog SHALL publicar artigos nas categorias: desenvolvimento semana a semana (52 artigos), desenvolvimento mês a mês (24 artigos), dúvidas comuns (200+ artigos), guias práticos (50+ artigos) e datas comemorativas (20+ artigos).
2. THE Blog SHALL seguir a estrutura: H1 com keyword principal, resposta direta nos primeiros 2–3 parágrafos, headings hierárquicos H2/H3, CTA contextual para o produto e schema JSON-LD adequado ao tipo de conteúdo (Article, FAQ ou HowTo).
3. THE Blog SHALL exibir no máximo 3 anúncios AdSense por página, posicionados após o 2º parágrafo, no meio do conteúdo e antes do CTA final.
4. THE Blog SHALL carregar anúncios AdSense com lazy loading para não impactar os Core Web Vitals.
5. THE Blog SHALL exibir data de publicação e data de última atualização em todos os artigos.
6. THE Blog SHALL incluir alt text descritivo em todas as imagens dos artigos.
7. IF o conteúdo de um artigo contém informações médicas ou de saúde, THEN THE Blog SHALL exibir disclaimer informando que o conteúdo é informativo e não substitui orientação médica profissional.

---

### Requisito 15: Upsells e Produtos Individuais

**User Story:** Como Comprador que deseja mais itens além do pack básico, quero poder adquirir produtos adicionais, para que eu tenha mais opções de memórias e presentes.

#### Critérios de Aceitação

1. THE Sistema SHALL oferecer os seguintes upsells de músicas na Tela_de_Escolha e na Tela_de_Entrega: "+1 música extra" por R$9,90 (segunda Canção_Completa favorita, já gerada) e "Pack 4 músicas" por R$19,90 (todas as 4 Canções_Completas geradas).
2. THE Sistema SHALL oferecer os seguintes upsells adicionais: Pack 3 estilos de arte (R$59,90), Versão animada para Stories (R$14,90), Vídeo com música + fotos (R$49,90), Quadro físico A4 com moldura (R$89,90) e Canvas premium A3 (R$149,90).
3. THE Sistema SHALL oferecer os cinco itens do pack individualmente com os preços âncora: Canção de Ninar (R$29,90), Arte Personalizada (R$24,90), Poster O Mundo Quando Nasceu (R$19,90), Significado do Nome (R$14,90) e Guia Primeiros Meses (R$19,90).
4. WHEN o Comprador seleciona um upsell de produto físico (quadro ou canvas), THE Sistema SHALL enviar a arte em alta resolução para a gráfica parceira via API após confirmação do pagamento.
5. WHEN o upsell físico é despachado pela gráfica parceira, THE Sistema SHALL enviar email ao Comprador com código de rastreamento.
6. THE Sistema SHALL validar no backend o valor total do pedido incluindo upsells, nunca confiando no valor enviado pelo cliente.

---

### Requisito 16: Analytics e Métricas

**User Story:** Como operador da plataforma, quero rastrear as métricas de conversão e uso, para que eu possa tomar decisões baseadas em dados para melhorar o produto.

#### Critérios de Aceitação

1. THE Sistema SHALL integrar PostHog para rastrear os seguintes eventos: visualização da landing page, início do fluxo de compra, conclusão de cada etapa do Formulário, início do checkout, confirmação de pagamento, escolha da Canção_Escolhida, download do Pack e clique em upsell.
2. THE Sistema SHALL rastrear as seguintes métricas: taxa de conversão LP → Checkout (meta: >5%), taxa de conversão Checkout → Pagamento (meta: >60%), tempo de geração do Pack (meta: <2 minutos) e taxa de upsell (meta: >15%).
3. THE Sistema SHALL nunca incluir dados pessoais identificáveis (nome, email, foto) nos eventos de analytics enviados ao PostHog.
4. WHEN o tempo de geração do Pack excede 5 minutos, THE Sistema SHALL registrar alerta nos logs internos para investigação.
