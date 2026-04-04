# NossoBebê — Guia de Marca

## Essência

NossoBebê é uma marca brasileira que transforma o nascimento de um bebê em memórias personalizadas com inteligência artificial. O produto principal é o **Pack Comemorativo**: uma canção de ninar exclusiva gerada por IA, arte do bebê, poster "O Mundo Quando Você Nasceu", arte com o significado do nome e um guia para os primeiros meses.

A marca fala com **pais e familiares** de recém-nascidos. O tom é acolhedor, emocional e moderno — como o quarto de um bebê: madeira, linho, algodão, luz quente.

---

## Paleta de Cores

### Cores Principais

| Nome       | Hex       | RGB              | Uso Principal                                                  |
|------------|-----------|------------------|----------------------------------------------------------------|
| Crafts     | `#E9E6DA` | 233, 230, 218    | Fundo principal do site, backgrounds de seções, base geral     |
| Fairy-tale | `#E2A18A` | 226, 161, 138    | CTAs, botões, links ativos, preços, elementos de destaque      |
| Crib       | `#896450` | 137, 100, 80     | Textos, headings, footer, navbar, elementos de corpo           |

### Cores de Apoio

| Nome    | Hex       | RGB              | Uso Principal                                                     |
|---------|-----------|------------------|-------------------------------------------------------------------|
| Hamper  | `#DDB068` | 221, 176, 104    | Badges de desconto, selos "Presente", destaques premium, estrelas |
| Rhymes  | `#BEC6AB` | 190, 198, 171    | Confirmações, selos de segurança, indicadores de sucesso, tags    |
| Musical | `#8BA4B5` | 139, 164, 181    | Ícones, links secundários, bordas, elementos informativos         |

### Hierarquia de Uso

```
Fundo/Base ........... Crafts (#E9E6DA)
Texto principal ...... Crib (#896450)
Texto secundário ..... Crib com 70% opacidade
Ação primária ........ Fairy-tale (#E2A18A)
Ação primária hover .. Fairy-tale escurecido 10% (#D4897A)
Ação secundária ...... Musical (#8BA4B5)
Destaque/Badge ....... Hamper (#DDB068)
Sucesso/Confiança .... Rhymes (#BEC6AB)
Erro/Alerta .......... #C97B6B (derivado do Fairy-tale, mais quente)
Divisores/Bordas ..... Crib com 20% opacidade
```

### Combinações Proibidas

- Texto Rhymes sobre fundo Crafts (contraste insuficiente)
- Texto Hamper sobre fundo Crafts (contraste insuficiente)
- Texto Musical sobre fundo Musical (óbvio, mas evitar variações próximas)
- Nunca usar preto puro (#000000) — usar sempre Crib (#896450) ou Crib escurecido

### CSS Variables

```css
:root {
  /* Cores principais */
  --color-crafts: #E9E6DA;
  --color-fairy-tale: #E2A18A;
  --color-crib: #896450;

  /* Cores de apoio */
  --color-hamper: #DDB068;
  --color-rhymes: #BEC6AB;
  --color-musical: #8BA4B5;

  /* Derivadas */
  --color-fairy-tale-hover: #D4897A;
  --color-fairy-tale-light: #F0C4B5;
  --color-crib-70: rgba(137, 100, 80, 0.7);
  --color-crib-20: rgba(137, 100, 80, 0.2);
  --color-error: #C97B6B;

  /* Semânticas */
  --color-bg: var(--color-crafts);
  --color-text: var(--color-crib);
  --color-text-secondary: var(--color-crib-70);
  --color-primary: var(--color-fairy-tale);
  --color-primary-hover: var(--color-fairy-tale-hover);
  --color-secondary: var(--color-musical);
  --color-accent: var(--color-hamper);
  --color-success: var(--color-rhymes);
  --color-border: var(--color-crib-20);
}
```

### Tailwind Config

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        crafts: '#E9E6DA',
        'fairy-tale': '#E2A18A',
        crib: '#896450',
        hamper: '#DDB068',
        rhymes: '#BEC6AB',
        musical: '#8BA4B5',
        'fairy-tale-hover': '#D4897A',
        'fairy-tale-light': '#F0C4B5',
        error: '#C97B6B',
      },
    },
  },
}
```

---

## Tipografia

### Fontes

| Uso            | Fonte                  | Peso        | Fallback                |
|----------------|------------------------|-------------|-------------------------|
| Headings       | **Playfair Display**   | 600–700     | Georgia, serif          |
| Corpo          | **Inter**              | 400–500     | system-ui, sans-serif   |
| Destaques/CTA  | **Inter**              | 600         | system-ui, sans-serif   |
| Handwritten    | **Caveat**             | 400–700     | cursive                 |

### Escala Tipográfica

```
H1 .... 2.5rem / 40px — Playfair Display 700 — cor Crib
H2 .... 2rem / 32px   — Playfair Display 600 — cor Crib
H3 .... 1.5rem / 24px — Playfair Display 600 — cor Crib
H4 .... 1.25rem / 20px — Inter 600 — cor Crib
Body .. 1rem / 16px    — Inter 400 — cor Crib
Small . 0.875rem / 14px — Inter 400 — cor Crib 70%
Caption 0.75rem / 12px  — Inter 400 — cor Crib 70%
```

### Regras

- Headings sempre em Crib (#896450), nunca em preto
- Corpo de texto em Crib, secundário em Crib 70%
- Links em Fairy-tale, underline on hover
- Botões em Inter 600, uppercase apenas para CTAs pequenos
- Caveat reservada para elementos decorativos: dedicatórias, "feito com amor", assinaturas

---

## Tom de Voz

### Personalidade

A marca NossoBebê fala como uma **amiga próxima que acabou de ter um filho** — carinhosa, animada, acolhedora, sem ser infantilizada ou excessivamente técnica.

### Princípios

1. **Emocional antes de racional** — "Uma canção só dele" antes de "gerada por inteligência artificial"
2. **Simples e direto** — Frases curtas, vocabulário acessível, sem jargão tech
3. **Celebratório** — O nascimento é uma festa, a comunicação reflete isso
4. **Inclusivo** — Mães, pais, avós, tios, padrinhos — todo mundo é bem-vindo
5. **Sem diminutivos excessivos** — "bebê" sim, "bebezinho fofo lindinho" não

### Exemplos

| Situação           | Sim ✓                                         | Não ✗                                          |
|--------------------|------------------------------------------------|------------------------------------------------|
| CTA principal      | "Crie as memórias do seu bebê"                | "COMPRE AGORA!!!"                              |
| Descrição produto  | "Uma canção de ninar única, feita só pra ele" | "Música gerada por modelo de IA generativa"    |
| Confirmação        | "Tudo pronto! Seu pack está sendo preparado"  | "Pedido #4872 processado com sucesso"          |
| Modo presente      | "Presenteie com algo que dura pra sempre"     | "Comprar voucher de presente"                  |
| Erro               | "Ops, algo deu errado. Tenta de novo?"        | "Error 500: Internal Server Error"             |

### Palavras-chave da Marca

Usar com frequência: **memória, único, especial, momento, família, canção, história, presente, celebrar, chegada, amor**

Evitar: **algoritmo, machine learning, automatizado, sistema, plataforma, engine, pipeline**

---

## Logo

### Conceito

O logo do NossoBebê é um coração em Fairy-tale (#E2A18A) contendo dois pezinhos de bebê em Crib (#896450), com ondas sonoras em Musical (#8BA4B5) saindo do topo esquerdo — representando a canção de ninar personalizada. O wordmark "NossoBebê" aparece abaixo em tipografia script, cor Crib.

### Versões Necessárias

| Versão                | Uso                                           |
|-----------------------|-----------------------------------------------|
| Logo completo         | Header do site, materiais institucionais      |
| Logo compacto         | Favicon, app icon, avatar em redes sociais    |
| Logo monocromático    | Marca d'água nos produtos, impressão P&B      |
| Logo sobre foto       | Posts de Instagram, thumbnails de blog         |

### Tamanhos e Arquivos

**Site (Next.js)**

| Arquivo                | Tamanho      | Uso                                              |
|------------------------|--------------|--------------------------------------------------|
| logo-full.svg          | vetorial     | Header navbar (preferível para escalar sem perda) |
| logo-full.png          | 400×120 px   | Fallback header, emails                          |
| logo-compact.png       | 192×192 px   | Ícone sem texto (só o coração com pezinhos)      |
| favicon.ico            | 48×48 px     | Aba do navegador                                 |
| favicon.svg            | vetorial     | Favicon moderno (browsers atuais)                |
| apple-touch-icon.png   | 180×180 px   | Ícone ao salvar no iPhone                        |
| og-image.png           | 1200×630 px  | Preview em WhatsApp, Facebook, LinkedIn          |
| android-chrome-192.png | 192×192 px   | PWA Android                                      |
| android-chrome-512.png | 512×512 px   | PWA Android splash                               |

**Instagram**

| Arquivo              | Tamanho    | Uso                                               |
|----------------------|------------|----------------------------------------------------|
| profile.png          | 320×320 px | Foto de perfil (ícone compacto, só o coração)      |
| post-logo.png        | 400×400 px | Para sobrepor em posts quando necessário            |
| stories-watermark.png| 200×60 px  | Logo transparente pequeno para canto de stories     |

**Email (Resend)**

| Arquivo              | Tamanho    | Uso                                               |
|----------------------|------------|----------------------------------------------------|
| email-header.png     | 300×90 px  | Topo dos emails, centralizado                      |
| email-header@2x.png  | 600×180 px | Versão retina (servir com width=300)               |

**Mercado Pago / Checkout**

| Arquivo              | Tamanho    | Uso                                               |
|----------------------|------------|----------------------------------------------------|
| checkout-logo.png    | 200×60 px  | Logo no checkout do Mercado Pago                   |

**Geral / Multiuso**

| Arquivo              | Tamanho    | Uso                                               |
|----------------------|------------|----------------------------------------------------|
| logo-full@2x.png     | 800×240 px | Versão alta resolução para qualquer uso            |
| logo-white.png       | 400×120 px | Versão em Crafts/branco para fundos escuros        |
| logo-mono.png        | 400×120 px | Versão monocromática em Crib para marca d'água     |

### Espaço de Proteção

Manter ao redor do logo um espaço mínimo equivalente à altura da letra "N" do wordmark. Nenhum elemento externo deve invadir essa área.

### Aplicação sobre fundos

- Fundo Crafts (#E9E6DA): usar logo em Crib (#896450) — versão padrão
- Fundo escuro/foto: usar logo em Crafts (#E9E6DA) ou branco
- Fundo Fairy-tale: usar logo em Crib (#896450)
- Nunca colocar o logo sobre fundos com muito ruído visual sem overlay

---

## Componentes Visuais

### Botões

```
Primário:
  bg: Fairy-tale (#E2A18A)
  text: Crafts (#E9E6DA)
  hover bg: Fairy-tale-hover (#D4897A)
  border-radius: 8px
  padding: 12px 24px
  font: Inter 600

Secundário:
  bg: transparent
  text: Crib (#896450)
  border: 1.5px solid Crib 20%
  hover border: Fairy-tale
  hover text: Fairy-tale
  border-radius: 8px

Ghost:
  bg: transparent
  text: Musical (#8BA4B5)
  hover text: Crib
  sem borda
```

### Cards

```
bg: white ou Crafts com leve elevação
border: 1px solid Crib 10%
border-radius: 12px
shadow: 0 2px 8px rgba(137, 100, 80, 0.08)
padding: 24px
```

### Badges

```
Desconto/Oferta:
  bg: Hamper (#DDB068)
  text: white
  border-radius: 20px
  font: Inter 600, 12px, uppercase

Presente:
  bg: Fairy-tale-light (#F0C4B5)
  text: Crib (#896450)
  border-radius: 20px

Sucesso:
  bg: Rhymes (#BEC6AB)
  text: Crib (#896450)
  border-radius: 20px
```

### Ícones

- Estilo: outline, stroke 1.5px
- Cor padrão: Crib (#896450)
- Cor ativa/hover: Fairy-tale (#E2A18A)
- Biblioteca recomendada: Lucide Icons (consistente com o estilo clean)
- Tamanho padrão: 20px (body), 24px (nav), 16px (inline)

---

## Imagens e Fotografia

### Diretrizes

- Tom quente, luz natural, dourada
- Ambientes: quartos de bebê, ambientes caseiros com madeira e tons neutros
- Pessoas: diversidade de etnias, tipos de família (mãe solo, casal, avós)
- Evitar: fotos de banco de imagem genéricas, fundos brancos clínicos, saturação excessiva
- Filtro/tratamento: leve warm overlay que puxe para a paleta Crafts/Crib

### Estilo de Ilustrações (quando usadas)

- Traço fino, orgânico, hand-drawn feel
- Cores da paleta, nunca cores fora dela
- Estilo: algo entre editorial e infantil — sofisticado mas acessível
- Referências: ilustrações tipo Rifle Paper Co., Lotta Nieminen

---

## Redes Sociais

### Instagram

- Grid com alternância entre: produto (mockup), emocional (foto bebê), educacional (dica), social proof (depoimento)
- Stories: fundo Crafts, texto Crib, destaques em Fairy-tale
- Reels: thumbnail com overlay Crafts 80% + texto Crib grande

### Paleta para Posts

```
Fundo tipo A: Crafts (#E9E6DA)
Fundo tipo B: Fairy-tale-light (#F0C4B5)
Fundo tipo C: Musical com 30% opacidade
Texto sempre: Crib (#896450)
Destaque: Hamper (#DDB068)
```

---

## Email

### Estrutura Visual

- Fundo externo: Crafts (#E9E6DA)
- Container: branco (#FFFFFF) com border-radius sutil
- Header: logo centralizado sobre Crafts
- Headings: Crib (#896450)
- Botão CTA: Fairy-tale (#E2A18A) com texto branco
- Footer: Crib 70% sobre Crafts
- Separadores: linha fina em Crib 15%

---

## Aplicação nos Produtos

### Pack Comemorativo

| Item                        | Cores dominantes                    |
|-----------------------------|-------------------------------------|
| Canção de ninar (player)    | Musical + Crib + Fairy-tale (play)  |
| Arte IA do bebê             | Paleta livre, moldura em Crib       |
| Poster "O Mundo Quando..."  | Crafts fundo, Crib texto, Hamper destaques |
| Arte significado do nome    | Fairy-tale + Crib                   |
| Guia primeiros meses        | Crafts fundo, Crib texto            |

### Impressos (upsell físico)

- Papel: off-white/creme (nunca branco alvejado) — deve parecer com Crafts impresso
- Tipografia: manter Playfair Display para headings
- Acabamento: fosco (combina com a paleta terrosa)

---

## Resumo Rápido

```
Fundo .............. #E9E6DA (Crafts — creme acolhedor)
Texto .............. #896450 (Crib — marrom quente)
Ação ............... #E2A18A (Fairy-tale — salmão/terracota)
Destaque ........... #DDB068 (Hamper — dourado/mostarda)
Confiança .......... #BEC6AB (Rhymes — verde sálvia)
Informação ......... #8BA4B5 (Musical — azul acinzentado)
Preto .............. NUNCA usar #000. Sempre Crib.
Branco puro ........ Evitar. Preferir Crafts como "branco".
Tom de voz ......... Acolhedor, emocional, simples, celebratório.
Fontes ............. Playfair Display (títulos) + Inter (corpo) + Caveat (decorativo).
```
