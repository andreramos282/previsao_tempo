// Respostas no mesmo formato do serviço XML do CPTEC/INPE.

const xmlCidades = '''<?xml version="1.0" encoding="ISO-8859-1"?>
<cidades>
  <cidade><nome>Jacareí</nome><uf>SP</uf><id>2641</id></cidade>
  <cidade><nome>Jacarezinho</nome><uf>PR</uf><id>2642</id></cidade>
</cidades>''';

const xmlPrevisao = '''<?xml version="1.0" encoding="ISO-8859-1"?>
<cidade>
  <nome>Jacareí</nome>
  <uf>SP</uf>
  <atualizacao>2026-11-06</atualizacao>
  <previsao><dia>2026-11-06</dia><tempo>ps</tempo><maxima>31</maxima><minima>17</minima><iuv>11.0</iuv></previsao>
  <previsao><dia>2026-11-07</dia><tempo>pn</tempo><maxima>29</maxima><minima>18</minima><iuv>10.0</iuv></previsao>
  <previsao><dia>2026-11-08</dia><tempo>pt</tempo><maxima>26</maxima><minima>18</minima><iuv>7.0</iuv></previsao>
  <previsao><dia>2026-11-09</dia><tempo>c</tempo><maxima>22</maxima><minima>16</minima><iuv>4.0</iuv></previsao>
</cidade>''';
