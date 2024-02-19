# Visão geral
Um Jogo da Velha de terminal simples e completo feito em Assembly x86 para Windows baseado em 32 e 64 bits. Neste programa foi utilizado chamadas básicas de funções do kernel do Windows, como chamadas para impressão no arquivo de saída padrão (WriteFile), para entrada de dados (ReadFile), para alocar memória no heap (HeapAlloc), entre outras funções. O motivo pela qual eu escrevi este programa em Assembly foi para compreender melhor o funcionamento de programas, entender um pouco mais sobre a arquitetura do computador e por conta da paixão em computação e programação de baixo nível. Eu escrevi este programa com base no mesmo programa escrito em C, seguindo as mesmas estruturas, funções e lógicas.

# Funcionamento
Seu funcionamento inclui um loop eterno que imprime a tabela 3 por 3, gerencia os jogadores, obtém a entrada do usuário para linha e coluna para ambos jogadores, válida a entrada do usuário, define o turno e verifica se há um ganhador ou empate. Toda alocação e liberação das estruturas são feitas manualmente no arquivo principal em funções como createGame e freeGame. Caso houver ganhador ou der empate o programa termina.

# Montagem e Ligação
O programa ja se encontra pronto na pasta [bin](bin/) mas caso queria fazer modificação basta fazer a modificação e rodar o arquivo batch no terminal com ```.\command.bat``` este arquivo comtém todos os commandos para montagem e ligação dos arquivos e por fim criando um arquivo executável na pasta bin. Na primeira execução pode-se notar uma lentidão na incialização por conta do anti-vírus do Windows.
