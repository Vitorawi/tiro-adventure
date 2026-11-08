# Referência única do bebê

Imagem fornecida pelo Vitor em 08/11/2026; `reference.png` é a fonte, sem redesenho.

`py tools/prepare_puppy_identity.py` copia a fonte para o jogo e gera dois recortes
exatos: corpo com 8 px de margem e cabeça `(214,136)-(524,372)`. Não redimensiona
nem altera cores. Os `.import` dos três derivados têm mipmaps ativados.

O corpo completo serve aos retratos, crescimento e cerimônia; o recorte de cabeça
ao HUD; o recorte frontal à introdução. A idle aprovada é outro arquivo e nunca é
sobrescrita. Os mapas mantêm a arte própria em pixel.
