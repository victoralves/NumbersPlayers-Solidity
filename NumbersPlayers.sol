pragma solidity ^0.4.17;

contract NumbersPlayers {

    address public donoJogo;

    enum EstadoJogo { ABERTO, AGUARDANDO_SAQUE, FECHADO }
    EstadoJogo public estadoJogo;

    uint256 public valorJogo;
    uint256 public quantidadeJogadores;
    
    uint8[] public numerosJogo;
    uint256 private numeroPremiado;
    uint256 public saldojogo;

    uint8 privete randomMin;
    uint8 privete randomMax;

    event LogAposta(address endereco);
    event LogNotificarGanhador(address endereco);


    mapping (address=>Jogador) mapAddressJogador;
    Jogador[] public jogadores;

    function NumbersPlayers() public {
        donoJogo = msg.sender;
        valorJogo = 1 ether;
        quantidadeJogadores = 3;
        numerosJogo = [1,2,3];
        estadoJogo = EstadoJogo.ABERTO;
        gerarNumeroPremiado();
    }

    function() public payable { }

    struct Jogador {
        address enderecoJogador;
        bool inscrito;
        uint8 jogo;
        bool vencedor;
    }

    // function gerarNumeroPremiado( 01 , 100 ) private {
    //     numeroPremiado = 2;
    // }
    function gerarNumeroPremiado(randomMin, randomMax) public returns (uint256){
        
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
        
        // This turns the input data into a 100-sided die
        // by dividing by ceil(2 ^ 256 / 100).
        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        return uint256(uint256(hashVal) / FACTOR) + 1;
    }

    function jogar(uint8 _jogo) payable public {
        require(msg.value == valorJogo);
        require(estadoJogo == EstadoJogo.ABERTO);

        assert(!mapAddressJogador[msg.sender].inscrito);

        Jogador memory jogador = Jogador({
            enderecoJogador: msg.sender,
            inscrito: true,
            jogo: _jogo,
            vencedor: false
        });

        mapAddressJogador[msg.sender] = jogador;
        jogadores.push(jogador);
        
        saldojogo += msg.value;

        this.transfer(msg.value);

        LogAposta(msg.sender);


        verificarQuantidadeApostas();
    }

    function sacarPremio() public {
        require(mapAddressJogador[msg.sender].inscrito);
        require(estadoJogo == EstadoJogo.AGUARDANDO_SAQUE);
        require(mapAddressJogador[msg.sender].vencedor);

        estadoJogo = EstadoJogo.FECHADO;        
        msg.sender.transfer(this.balance);
    }

    function consultarNumeroPremiado() public view returns (uint256) {
        require(estadoJogo == EstadoJogo.FECHADO);
        return numeroPremiado;
    }

    function quantidadeJogadores() public view returns(uint256) {
        return jogadores.length;
    }

    function estadoJogo() public view returns(string) {
        if (estadoJogo == EstadoJogo.ABERTO) {
            return "ABERTO";
        } else if (estadoJogo == EstadoJogo.AGUARDANDO_SAQUE) {
            return "AGUARDANDO_SAQUE";
        } else {
            return "FECHADO";
        }
    }

    function verificarQuantidadeApostas() private {
        if (quantidadeJogadores == jogadores.length) {
            LogNotificarGanhador(verificarGanhador());
        }
    }

    function verificarGanhador() private returns(address) {
        for (uint i = 0; i < jogadores.length; i++) {
            if (jogadores[i].jogo == numeroPremiado) {
                jogadores[i].vencedor = true;
                mapAddressJogador[jogadores[i].enderecoJogador].vencedor = true;
                estadoJogo = EstadoJogo.AGUARDANDO_SAQUE;
                return jogadores[i].enderecoJogador;
            }
        }
    }

}