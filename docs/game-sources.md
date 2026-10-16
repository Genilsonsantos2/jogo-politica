# Fontes e escopo — Brasil em Jogo

Verificação e obtenção local para o protótipo em outubro de 2026.

## Geografia

- **API de Malhas Geográficas do IBGE**, documentação v3: <https://servicodados.ibge.gov.br/api/docs/malhas?versao=3>. O endpoint por país aceita `intrarregiao=uf` e GeoJSON simplificado; a geometria armazenada em `data/brazil_states.geojson` serve à visualização do mapa.
- **API de Localidades do IBGE**: <https://servicodados.ibge.gov.br/api/docs/localidades>. Os nomes e identificadores de unidades federativas e municípios usados pelo filtro offline foram consultados em `https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome` e `https://servicodados.ibge.gov.br/api/v1/localidades/municipios?orderBy=nome`.
- A página de malhas do IBGE descreve os arquivos municipais e a disseminação de 2025: <https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/15774-malhas.html>.

## Votação

- **TSE, “Faltam 25 dias: saiba qual é a ordem de votação na urna eletrônica” (9 set. 2026)**: <https://www.tse.jus.br/comunicacao/noticias/2026/Setembro/faltam-25-dias-saiba-qual-e-a-ordem-de-votacao-na-urna-eletronica>. O texto descreve a conferência de foto, nome e partido, as teclas de corrigir/confirmar, e a possibilidade de voto em branco; também lista o tamanho numérico dos cargos nas eleições gerais de 2026. O jogo usa o padrão apenas como referência pedagógica, com candidaturas e resultados fictícios.

## Organização política

- **Constituição da República Federativa do Brasil (texto compilado do Planalto)**: <https://www.planalto.gov.br/ccivil_03/constituicao/constituicaocompilado.htm>. Referências de escopo: art. 2º (Poderes da União); arts. 18 e 25 (organização federativa e Estados); arts. 29–30 (Municípios). A simulação não pretende modelar todos os artigos, competências comuns ou concorrentes, processos recursais nem exceções.

## Limites e dados

- O mapa usa malha simplificada para navegação visual, não para medição, navegação, delimitação fundiária ou decisão oficial.
- O catálogo de municípios oferece nomes reais para localização; indicadores, finanças, serviços, eventos, propostas, candidaturas, partidos, votos e apurações do jogo são dados sintéticos.
- Não existe comunicação do jogo com TSE, TRE, IBGE ou qualquer sistema eleitoral em tempo de execução. Resultados não têm validade eleitoral.
- No Brasil não há Poder Judiciário municipal. A tela judicial do nível municipal representa, de forma educativa, a revisão por órgãos estaduais ou federais competentes; nos níveis estadual e federal, a interface também é uma simplificação institucional.
