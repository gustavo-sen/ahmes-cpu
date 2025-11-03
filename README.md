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
>iverilog -g2012 -o name_sim UC.sv TOP.sv PMEM.sv DPATH.sv tb_TOP.sv

Simular tesbench
>vvp name_sim

### Simular no terminal p/ VHDL
1. Sintetizar entidade desejada
> ghdl -a ahmes_uc.vhd

2. Sinteizar testbench da entidade em teste
> ghdl -a tb_ahmes_uc.vhd

3. Gerar arquivos de simulação
> ghdl -e tb_ahmes_uc
> ghdl -r tb_ahmes_uc --vcd=wave.vcd

### Simular com GtkWave
Para usar o GtkWave e visualizar os sinais:
gera um arquivo com um tempo de simulação 
> ghdl -r tb_enitty --stop-time=100ms --vcd=nome_da_simulacao.vcd
executa o arquivo gerado
> gtkwave wave.vcd


### Teste Rápido carregando "memoria_soma.vhd"
ghdl -a ALU.vhd
ghdl -a memoria_soma.vhd
ghdl -a ahmes_uc.vhd
ghdl -a tb_ahmes_uc.vhd
ghdl -e tb_ahmes_uc
ghdl -r tb_ahmes_uc --vcd=simulacao.vcd
gtkwave simulacao.vcd


### Teste Rápido carregando "memoria_led.vhd"
ghdl -a ALU.vhd
ghdl -a memoria_led.vhd
ghdl -a ahmes_uc.vhd
ghdl -a tb_ahmes_uc.vhd
ghdl -e tb_ahmes_uc
ghdl -r tb_ahmes_uc --vcd=simulacao.vcd
gtkwave simulacao.vcd

### Teste SPI
ghdl -a spi_loader.vhd                                    
ghdl -a tb_spi_loader.vhd
ghdl -e tb_spi_loader
ghdl -r tb_spi_loader --vcd=spi_loader.vcd --stop-time=3us
gtkwave spi_loader.vcd  