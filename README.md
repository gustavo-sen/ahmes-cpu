# AHMES CPI

## Sobre

## Especificações do projeto

## Simulation
 - pre-requisitos VHDL:
   - instalar ghdl
   - intalar gtk wave
 
 - pre-requisitos SystemVerilog:
   - instalar icarus
   - instalar gtk wave

### Simular no terminal p/ SystemVerilog

Sintetizar com icuarus
>iverilog -g2012 -o name_sim module_name.sv tb_module_name.sv

Simular tesbench
>vvp name_sim

### Simular no terminal p/ VHDL
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
> ghdl -r tb_enitty --stop-time=100ms --vcd=nome_da_simulacao.vcd
executa o arquivo gerado
> > gtkwave nome_da_simulacao.vcd

