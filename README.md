# ahmes-cpu

## Simulation
 - pre-requisitos:
   - instalar ghdl
   - intalar gtk wave

Sintetizar entidade desejada
> ghdl -a entity_name.vhd

Sinteizar testbench da entidade em teste
> ghdl -a tb_entity_name.vhd

Gerar arquivos de simulação
> ghdl -e tb_entity_name
> ghdl -r tb_entity_name
