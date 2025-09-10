# ahmes-cpu

## Simulation
 - pre-requisitos:
   - instalar ghdl
   - intalar gtk wave

### Simular no terminal
Sintetizar entidade desejada
> ghdl -a entity_name.vhd

Sinteizar testbench da entidade em teste
> ghdl -a tb_entity_name.vhd

Gerar arquivos de simulação
> ghdl -e tb_entity_name
> ghdl -r tb_entity_name

### Simular com GtkWave
Para usar o GtkWave e visualizar os sinais:
gera um arquivo com um tempo de simulação 
> ghdl -r tb_enitty --stop-time=100ms --vcd=wave.vcd
executa o arquivo gerado
> > gtkwave wave.vcd

