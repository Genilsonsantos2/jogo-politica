# Brasil em Jogo

**Brasil em Jogo** é um protótipo offline de simulação política e social em português brasileiro. O jogador acompanha uma comunidade e experimenta decisões nos níveis municipal, estadual e federal, observando efeitos sobre serviços, orçamento, normas e confiança pública.

## Jogar

- Use a lista no cabeçalho para alternar entre **Município**, **Estado** e **País / União**.
- Explore **Executivo**, **Legislativo**, **Judiciário** e **Comunidade** no menu lateral.
- No Executivo, escolha uma política e acompanhe seus custos e efeitos nos indicadores.
- No Legislativo, debata propostas fictícias e aprove normas.
- No painel do Judiciário, analise uma revisão didática de normas em vigor.
- Avance o trimestre para atualizar receitas, despesas e acontecimentos simulados.
- Em **Eleições e urna**, escolha uma votação de demonstração. Digite os números ou use o teclado na tela; confira o nome, a fotografia e o partido, corrija ou marque voto em branco e confirme.
- Em **Escolher cidade**, filtre o catálogo de municípios por estado e nome.

O progresso de gestão fica salvo localmente neste dispositivo. Não há conta, placar, conexão com backend nem coleta de voto eleitoral. As candidaturas, propostas, notícias e resultados eleitorais são inventados e ilustrativos.

## Aviso eleitoral e escopo educativo

A urna deste jogo é uma **simulação fictícia para educação e entretenimento**, sem afiliação ou conexão com o Tribunal Superior Eleitoral (TSE), sem integração com sistemas oficiais e sem validade eleitoral. Não digite dados pessoais. A escolha individual de voto não é persistida; somente o resultado fictício agregado da sessão pode ser guardado.

A simulação reduz processos e competências para caber num jogo. No Brasil, o Judiciário é independente e não existe Poder Judiciário municipal: questões locais podem ser apreciadas por órgãos judiciais estaduais ou federais, conforme a competência. A tela judicial esclarece essa distinção. O conteúdo não substitui informação cívica oficial nem orientação jurídica.

## Dados geográficos

- As geometrias simplificadas das 27 unidades federativas e o catálogo de municípios foram obtidos pela API oficial de malhas e pela API de Localidades do IBGE. Os arquivos necessários estão empacotados localmente, então o jogo pode ser usado sem internet.
- A interface de voto inspira-se no fluxo público descrito pelo TSE (digitar, conferir, corrigir ou confirmar), mas não reproduz software, infraestrutura, marca ou resultado oficial.
- As fontes e a nota sobre escopo estão em [`docs/game-sources.md`](docs/game-sources.md).

## Ambiente de desenvolvimento

O projeto usa Godot 4 e exportação para navegador pelo fluxo gerenciado do Manus. O ponto de entrada é `scenes/main.tscn`; o modelo offline fica em `scripts/game/civic_simulation.gd` e o mapa em `scripts/ui/brasil_map.gd`.
