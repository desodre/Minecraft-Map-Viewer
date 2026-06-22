# Minecraft Seed Map Viewer 🗺️

Este projeto é o frontend de uma ferramenta de pré-visualização interativa de mundos de Minecraft em 2D baseada inteiramente na Seed do mundo. A aplicação foi escrita em Flutter com foco em interfaces performáticas, renderização otimizada de mapas e transições fluidas.

---

## ✨ Funcionalidades Principais

* **Arquitetura Slippy Map Customizada**: Renderização eficiente de tiles de $256 \times 256$ pixels carregados sob demanda a partir das coordenadas Minecraft $(X, Z)$ visíveis na tela.
* **Navegação Fluida por Gestos**: Suporte nativo a gestos de arrastar (pan) e pinça (pinch-to-zoom) para telas sensíveis ao toque.
* **Suporte Completo a Desktop & Web**:
  * **Zoom pelo Scroll do Mouse**: Controle de aproximação por roda de rolagem do mouse direcionado exatamente à posição atual do cursor.
  * **Botões de Zoom em Tela**: Botões flutuantes de `+` e `-` para controle de zoom com animações de aproximação suaves (300ms) mantendo o centro estabilizado.
* **Centralização no Spawn (0,0)**: Botão de atalho rápido estilo bússola/GPS para retornar a visualização suavemente à origem.
* **Painel de Coordenadas em Tempo Real**:
  * Exibição das coordenadas Minecraft $(X, Z)$ sob o cursor do mouse (ou sob a mira central).
  * Tradução instantânea para coordenadas de **Chunks** (grelha de $16 \times 16$ blocos).
  * Identificação automática do arquivo de região do Minecraft correspondente (ex: `r.-1.2.mca` correspondente a $512 \times 512$ blocos).
* **Grelha Dinâmica e Eixos do Minecraft**:
  * Eixos principais coloridos no padrão do jogo: Eixo X em vermelho (Leste/Oeste) e Eixo Z em verde (Norte/Sul).
  * Linhas de grelha que se adaptam dinamicamente dependendo do zoom (de grades finas de 16 blocos a limites maiores de regiões).
* **Tratamento Fino de Performance**:
  * Caching em nível de imagem nativo para evitar requisições redundantes de tiles já visitados.
  * Transição suave de opacidade (fade-in) nos tiles carregados.
  * Correção de seam lines (fissuras sub-pixel) com micro-sobreposições nas bordas dos tiles durante o zoom.
  * Fallbacks estéticos (estilo "Unloaded Chunk") caso o servidor local esteja offline.

---

## 🛠️ Arquitetura e Engenharia do Projeto

A aplicação foi estruturada usando o padrão de gerenciamento de estado **Provider**, desacoplando a lógica matemática de projeção e controle de coordenadas dos widgets de UI:

```
lib/
│
├── state/
│   └── map_state.dart              # Gerencia o Seed, coordenadas do centro do mapa, zoom e hover.
│
├── widget/
│   ├── tile_widget.dart            # Renderizador assíncrono e responsivo de um único tile (256x256).
│   └── minecraft_grid_painter.dart # CustomPainter para renderizar eixos, grelhas e marcadores de coordenadas.
│
├── page/
│   └── map_screen.dart             # Tela principal com viewport interativo, header (Seed) e footer (Coords).
│
└── main.dart                       # Ponto de entrada, configuração do tema escuro e injeção do MapState.
```

### 🧮 Matemática do Slippy Map Customizado
Para converter as coordenadas do Minecraft $(X, Z)$ em pixels de tela $(x, y)$ considerando um zoom double arbitrário:
1. **Fator de Escala (Blocks per Pixel)**:
   $$S = 2^{4 - zoom}$$
2. **Tamanho do Tile em Blocos**:
   $$W_b = 256 \times 2^{4 - z} \quad \text{onde } z = \text{round}(zoom)$$
3. **Mapeamento de Coordenada para Tela**:
   $$x_{\text{tela}} = \frac{\text{largura}}{2} + \frac{X - X_{\text{centro}}}{S}$$
   $$y_{\text{tela}} = \frac{\text{altura}}{2} + \frac{Z - Z_{\text{centro}}}{S}$$

Esta fórmula garante suporte perfeito a coordenadas negativas do Minecraft (ex: $X < 0$ ou $Z < 0$), algo frequentemente problemático em bibliotecas geográficas padrão como `flutter_map` (que usam projeções esféricas padrão Web Mercator).

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
* **Flutter SDK**: `>= 3.41.9`
* **Dart SDK**: `>= 3.11.5`

### Passo 1: Instalar dependências
Execute na raiz do projeto para baixar o pacote de gerência de estado `provider`:
```bash
flutter pub get
```

### Passo 2: Configurar o Servidor de Tiles (Backend)
O aplicativo espera que um servidor local esteja gerando e servindo as imagens dos tiles de mapa na seguinte rota:
```
http://localhost:8080/api/v1/map/tile?seed=$seed&zoom=$zoom&tx=$tx&ty=$ty
```
* **$seed**: Semente do mundo (String/Número).
* **$zoom**: Nível de zoom inteiro.
* **$tx, $ty**: Coordenadas de coluna e linha do tile (podendo assumir valores negativos).

*Dica: Caso o servidor backend não esteja de pé, o aplicativo exibirá blocos de terra rústicos com a inscrição "UNLOADED" nas coordenadas correspondentes.*

### Passo 3: Executar a aplicação
Para rodar a aplicação em modo de desenvolvimento (escolha Chrome, Linux desktop ou emulador conectado):
```bash
flutter run
```

---

## 🧪 Testes e Análise Estática

Verifique se todo o código segue os padrões do linter oficial do Flutter rodando a análise estática:
```bash
flutter analyze
```

Para executar a suite de testes unitários que valida a injeção de estado e integridade estrutural da tela de mapa:
```bash
flutter test
```
