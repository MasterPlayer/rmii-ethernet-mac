# rmii-ethernet-mac
RMII interface ethernet MAC Core for 10/100 MBit ethernet implementation with support CDC and AXI-Stream BUS without management and without MDIO interface support

![Схема](https://user-images.githubusercontent.com/45385195/150557171-c8f261c2-5799-43de-b611-a475b25cbab5.png)


## Eng

### Description

Single core for implementation MAC layer of RMII ethernet 

Physical layer presented by IC MicroChip LAN8720A-CP 

RMII - interface, which different from SGMII, RGMII, GMII. Work with two lines on each side. It is old interface, so old trat Xilinx stopped support this standart of this interface, removing ip core from ip catalog in Vivado.

Interface supports speed 10Mbit/100 MBit per second

In this case it necessary implement simple custom module for support this standart

### Clocking

Component 
The component provides for work with the transition along the clock domain through internal queues with the possibility of CDC. The internal logic is powered by the PHY_CLK clock signal, which comes from the physical layer. The ETH_RX_AXIS_* and ETH_TX_AXIS_* outputs are accompanied by their own CLK signals to provide more flexible operation. 

### Receive part 

Data received from two-bit data wire with PHY_CRS_DV signal as valid. This Stream deserialized from 2 to 8 bits, and latched to registry file, in which searching preamble of Ethernet (0x55555555555555) and SFD (StartFrameDelimiter = 0xD5), When this sequence founded, all next data is treated as Ethernet packet data.

![Data format from PHY IC](https://user-images.githubusercontent.com/45385195/150559053-fac0ec28-87ee-4b8d-80dd-f459432a45a9.png)

Checksum calculated for all data in packet, excluded PREAMBLE and SFD. Checksum calculated as CRC32

In case when packet was received with uncorrect CRC or with corrupted data, this packet goes to user logic with CRC_BAD signal. If packet CRC is good, packet goes to user logic with CRC_GOOD signal.

CRC_GOOD and CRC_BAD asserted for 1 clock period. 

Packet goes outside over FIFO with Cross Domain Crossing(CDC). Data width is 8 bit, protocol - AXI-Stream with support TVALID, TLAST, TREADY. ETH_RX_AXIS_TVALID signal can be deasserted inside the packet, if speed of external logic greater than internal logic PHY_CLK. 

### Transmit part

Data sends in packet mode. Packet collects in internal queue, and only after that goes to PHY layer. 
When packet from logic fully in internal FIFO (with signal TLAST), then FSM goes to transmit PREAMBLE data. 
FSM(FiniteStateMachine) transmit PREAMBLE, SFD, DATA and CRC. 

CRC calculates while data reads from internal fifo. 

Padding to 60 bytes, if input packet was small size not performed. 

Input 8 bit words transform to 2 bit words over component [rmii_serializer](https://github.com/MasterPlayer/rmii-ethernet-mac/blob/d7a2b9ed4b12035db87bcb60c9d02900f487736f/hw/rmii_serializer.sv)

CRC calculates automatically, user intervention not required

# Testing

Component RMII_ETHERNET connected with ethernet host, which can send responses for ARP/ICMP requests. Workability of component confirmed by the fact that there answern on PING requests. Host Code not presented in this project

# Limitations

1. Not tested 10Mbit/s Ethernet. Behaviour of PHY_INT(CLK) signal and CRS_DV signal unknown
2. No Padding for minimal packet size
3. No processing RXER
4. No MDIO interface support


## Rus 

### Описание

Простое ядро, реализующее уровень MAC для RMII Ethernet 

В качестве микросхемы физического уровня выступает MicroChip LAN8720A-CP 

RMII - это интерфейс, который в отличие от RGMII(4 линии), SGMII(дифференциальная пара), GMII(8 линий) работает по двум линиям передачи в каждую из сторон
Интерфейс достаточно старый, настолько старый что Xilinx перестали поддерживать данный стандарт Ethernet, убрав ядро из каталога. 

Скорости которые поддерживает данный интерфейс - это 10Мбит/с и 100 МБит/с Ethernet

В таком случае необходимо реализовать ядро, которое будет поддерживать данный режим работы своими руками. 

### Тактирование

Компонент предусматривает работу с переходом по clock domain через внутренние очереди с возможностью CDC. Внутренняя логика работает от сигнала тактирования PHY_CLK, который приходит с физического уровня. Выходы ETH_RX_AXIS_* и ETH_TX_AXIS_* сопровождаются своими сигналами CLK для обеспечения более гибкой работы. 

### Приемная часть 

Данные на прием поступают по двухбитной шине, сопровождаясь сигналом PHY_CRS_DV(который выступает в роли сигнала валидности данных). Поток данных десериализуется из 2 бит в 8 бит, защелкивается в регистровый файл, в котором, ищется преамбула Ethernet (0x55555555555555) и Start Frame Delimiter (0xD5). Когда данная последовательность найдена, все последующие данные считаются как тело пакета Ethernet. 

![Формат пакета от физики](https://user-images.githubusercontent.com/45385195/150559053-fac0ec28-87ee-4b8d-80dd-f459432a45a9.png)

Контрольная сумма считается по всему телу пакета, исключая преамбулу и StartFrameDelimiter. Контрольная сумма считается по CRC32. 

В случае, если пакет приходит с некорректной CRC, или искажен в момент приема, то он все равно будет выдан наружу в пользовательскую логику, сопровождаясь сигналом CRC_BAD. Если с пакетом все отлично, и CRC сходится, то он выдается наружу с сигналом CRC_GOOD

Выдача пакета наружу происходит через внутреннюю FIFO с возможностью CDC. Формат выдаваемых данных - 8 бит. Протокол - AXI-Stream. Допустимы падения валидов при передаче пакета в пользовательскую логику

### Передающая часть

Отправка пакета происходит в пакетном режиме. Пакет копится во внутренней очереди, и только потом передается на микросхему физического уровня. 

Когда пакет с логики полностью уложится во внутренней очереди(сопровождаясь сигналом TLAST), то это даст сигнал работе конечного автомата на передачу. 
Конечный автомат производит передачу PREAMBLE, SFD, DATA и CRC. 
CRC считается в момент вычитывания данных из внутренней очереди. 

Текущим пакетом называется обьем данных от первого сигнала VALID до сигнала TLAST включая его. 

Передающая часть не производит добивания пакета до 60 байт, если размер меньше заявленного. 

Поток с очереди перекручивается в двухбитовый поток внутри компонента [rmii_serializer](https://github.com/MasterPlayer/rmii-ethernet-mac/blob/d7a2b9ed4b12035db87bcb60c9d02900f487736f/hw/rmii_serializer.sv)


CRC на передающийся пакет считается самостоятельно, пользователю не требуется пересчитывать ее самому. 

# Тестирование

К компоненту подключен хост, способный формировать ответы arp/icmp. Работоспособность подтвердилась по факту наличия ответов на PING-запросы. Код хоста в данном проекте не представлен. 

# Ограничения компонента

1. Не проверялась работа с 10 МБит/с Ethernet, поведение сигнала тактирования или сигналов RXD/CRS_DV неизвестно
2. Нет добивания до минимального размера пакета
3. Нет обработки RXER
4. Нет MDIO интерфейса


# Version 

1.0 - Initial Release
