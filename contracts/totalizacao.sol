// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

error invalidQRPosition(uint positionExpected, uint8 positionReceived);

contract Totalizacao {

    mapping(bytes32 => BU) public bus; // os hashes serão sempre diferentes, devido às identificações diferentes nas eleições, como o número do processo eleitoral e o pleito
        
    ProcessoEleitoral[] public listaProcessos; 
    mapping(uint128 => uint128) private indiceProcesso; // indice somado de 1. 0 indica inexistência

// ---------------------------------------------

    struct ProcessoEleitoral {
        uint128 id; // número do processo eleitoral
        mapping(uint8 => Turno) turnos;
    }

    struct Turno {
        uint8 id; // 1 - primeiro turno; 2 - segundo turno
        uint32 pleito; // número do pleito
        uint32 dataPleito; // data do pleito
        mapping(uint32 => Eleicao) eleicoes;
    }

    struct Eleicao {
        mapping(bytes32 => Abrangencia) abrangencia; // Calculada através de hash (ZZ ou BR ou RJ ou RJ<MUNIC> ou ZZ<MUNIC> ou RJ<MUNIC><ZONA><SECAO>)
    }

    struct Abrangencia { // Exterior, Brasil, uma Unidade federativa do Brasil, Município ou urna específica
        mapping(uint8 => Cargo) cargos;
    }

    struct Cargo {
        CargoInfo info;
        mapping(uint128 => uint128) indiceCandidato; // mapeamento do candidato a um determinado cargo para o indice no vetor. 0 - indica inexistência
        mapping(uint128 => uint128) indicePartido; // somente para cargos proporcionais, mapeamento do partido em um determinado cargo para o indice no vetor. 0 - indica inexistência
    }

    struct CargoInfo {
        uint8 id; // código do cargo
        uint8 tipo; // tipo do cargo. Diferente do manual do QR Code, tipo 0 significa que o cargo está incompleto ou não existe. 1 – Majoritário; 2 – Proporcional; 3 – Consulta
        uint128 aptos; // quantidade de eleitores aptos a votarem no cargo
        uint128 csec; // quantidade de comparecimento no cargo sem candidatos
        uint128 nomi; // quantidade de votos nominais para o cargo
        uint128 legc; // quantidade de votos de legenda para o cargo - apenas para cargos proporcionais
        uint128 branco; // quantidade de votos em branco para o cargo
        uint128 nulo; // quantidade de votos nulos para o cargo
        uint128 totalVotosCargo; // total de votos apurados para o cargo
        Candidato[] candidatos; // lista de candidatos para o cargo e a quantidade de votos recebidas
        Partido[] partidos; // lista de partidos
    }

    struct Candidato {
        uint128 id; // identificação de um candidato referente a um cargo com determinada abrangência
        uint128 votos; // votos de um candidato referente a um cargo com determinada abrangência
    }

    struct Partido { // somente para cargos proporcionais
        uint32 id; // número do partido
        uint128 votosLegenda;
        uint128 totalPartido;
        uint128[] candidatosPartido; // lista de candidatos do partido para o cargo
    }
    

    struct BU {
        bytes32 idHash; // hash do conteúdo do primeiro QR Code
        bytes32 assinaturaParte1;
        bytes32 assinaturaParte2;
        uint128 proc; // número do processo eleitoral
        uint8 turno; // 1 - primeiro turno; 2 - segundo turno
        uint32 pleito; // número do pleito
        uint32 dataPleito; // data do pleito
        string unfe; // Unidade Federativa - Exemplo: RJ 
        uint128 municipio;
        uint128 zona;
        uint128 secao;
        QR[] qrs;
        uint128 quantQrsEsperado; // quantidade de qr codes esperado
        CheckPoint cp; // indica onde a inserção de um QR Code parou
    }

    struct QR {
        uint8 posicao; // posição do qr code diante do conjunto de qrs codes
        string qr; // conteúdo completo do QR Code
    }

    struct CheckPoint { // onde a inserção de um QR Code parou
        uint32 eleicao;
        uint8 cargo;
        uint32 partido;
    }

    struct Eleicoes {
        uint32 id;
        CargoInfo[] cargos;
    }

// ---------------------------------------------

    event QRCodeAdded(
        bytes32 hashBu,
        uint8 qrPosition
    );

    function registrar(BU calldata boletimUrna, Eleicoes[] calldata eleicoes) 
    public 
    returns(bytes32) { 

        bytes32 hashBu = boletimUrna.idHash;
        uint8 posicaoQR = boletimUrna.qrs[0].posicao;

        require(posicaoQR > 0, "Posicao do QR Code invalida");
        require(hashBu != bytes32(0), "Por favor, escaneie o primeiro QR Code antes deste"); // caso em que a leitura foi interrompida no meio do processo de inserção. Sinaliza à aplicação de que é necessário ler primeiro o primeiro QR Code para obter a identificação do BU
        require(posicaoQR != 1 || keccak256(abi.encodePacked(boletimUrna.qrs[0].qr)) == boletimUrna.idHash, "Hash da string do QR Code invalida"); // hash da string do QR Code é diferente da hash informada no parâmetro

        uint quantQRs = bus[hashBu].qrs.length;

        if (posicaoQR == 1) {

            if (bus[hashBu].idHash == bytes32(0)) { // caso em que são inseridos o cabeçalho do boletim de urna, primeiro QR Code

                uint128 numProcesso = boletimUrna.proc;
                uint8 idTurno = boletimUrna.turno;
                uint128 posicaoProcesso = indiceProcesso[numProcesso];

                bus[hashBu] = boletimUrna; // cria um tipo BU com as informações até então recebidas. Os dados são inseridos nesse BU para cada informação nova recebida, como um QR Code

                if(posicaoProcesso == 0) { // verifica se o processo eleitoral já está registrado

                    registraProcesso(boletimUrna, eleicoes, numProcesso); // registra a partir do processo eleitoral

                } else if(listaProcessos[posicaoProcesso - 1].turnos[idTurno].id == 0) { // com o processo eleitoral registrado, verifica-se se o turno já está registrado. Verificação necessária quando chegar no segundo turno das eleições, por exemplo.

                    registraTurno(boletimUrna, eleicoes, posicaoProcesso); // registra a partir do turno

                } else {

                    registraEleicoes(hashBu, eleicoes, listaProcessos[posicaoProcesso - 1].turnos[idTurno]);

                }

            }

        } else {

            if (bus[hashBu].idHash == bytes32(0)) {

                revert("Hash invalido");

            }

            if((posicaoQR == quantQRs + 1) && (posicaoQR <= bus[hashBu].quantQrsEsperado)) { // verifica se está na posição correta do QR Code

                uint8 idTurno = bus[hashBu].turno;
                uint128 idProc = bus[hashBu].proc;
                uint128 posicaoProcesso = indiceProcesso[idProc];

                registraEleicoes(hashBu, eleicoes, listaProcessos[posicaoProcesso - 1].turnos[idTurno]);

                bus[hashBu].qrs.push(boletimUrna.qrs[0]);

            }
        }

        if(posicaoQR <= quantQRs) {

            revert("QR Code ja adicionado");

        } else if (posicaoQR > quantQRs + 1) { // ordem inválida de inserção do QR Code

            revert invalidQRPosition({
                positionExpected: quantQRs + 1,
                positionReceived: posicaoQR
            });

        }

        if(posicaoQR == bus[hashBu].quantQrsEsperado) { // insere assinatura da urna contida no último QR Code

            bus[hashBu].assinaturaParte1 = boletimUrna.assinaturaParte1;
            bus[hashBu].assinaturaParte2 = boletimUrna.assinaturaParte2;

        }

        // garante que o checkpoint mantém o que está sendo inserido ao longo dos QRs Codes e só altera quando há um novo checkpoint
        if (bus[hashBu].cp.eleicao != boletimUrna.cp.eleicao && boletimUrna.cp.eleicao != 0) {
            bus[hashBu].cp.eleicao = boletimUrna.cp.eleicao;
        }

        if (bus[hashBu].cp.cargo != boletimUrna.cp.cargo && boletimUrna.cp.cargo != 0) {
            bus[hashBu].cp.cargo = boletimUrna.cp.cargo;
        }

        if (bus[hashBu].cp.partido != boletimUrna.cp.partido && boletimUrna.cp.partido != 0) {
            bus[hashBu].cp.partido = boletimUrna.cp.partido;
        }

        emit QRCodeAdded(hashBu, posicaoQR);
        return hashBu;
    }

    function registraProcesso(BU calldata boletimUrna, Eleicoes[] calldata eleicoes, uint128 numProcesso) private returns(bool) {

        uint128 posicaoProcesso = uint128(listaProcessos.length);

        listaProcessos.push();

        listaProcessos[posicaoProcesso].id = numProcesso;

        bool res = registraTurno(boletimUrna, eleicoes, posicaoProcesso);

        if (res) {
            indiceProcesso[numProcesso] = posicaoProcesso + 1;
        }

        return res;
    }

    function registraTurno(BU calldata boletimUrna, Eleicoes[] calldata eleicoes, uint128 posicaoProcesso) private returns(bool) {
        
        Turno storage turno = listaProcessos[posicaoProcesso].turnos[boletimUrna.turno];
        turno.id = boletimUrna.turno;
        turno.pleito = boletimUrna.pleito;
        turno.dataPleito = boletimUrna.dataPleito;

        return registraEleicoes(boletimUrna.idHash, eleicoes, turno);
    }

    function registraEleicoes(bytes32 idHash, Eleicoes[] calldata eleicoes, Turno storage turno) private returns (bool) {

        bytes32[4] memory abrange = [
            keccak256(abi.encodePacked(bus[idHash].unfe, bus[idHash].municipio, bus[idHash].zona, bus[idHash].secao)),
            keccak256(abi.encodePacked(bus[idHash].unfe, bus[idHash].municipio)), 
            keccak256(abi.encodePacked(bus[idHash].unfe)), 
            keccak256(abi.encodePacked("BR"))
        ];

        for (uint8 i; i < eleicoes.length; i++) {

            uint32 idEleicao = eleicoes[i].id;

            if (idEleicao == 0) { // resgata a identificação da eleição quando não há essa informação no início do conteúdo do QR Code
                idEleicao = bus[idHash].cp.eleicao;
            }

            Eleicao storage eleicao = turno.eleicoes[idEleicao]; // eleições federais e estaduais são consideradas eleições diferentes, porém ocorrem no mesmo processo eleitoral
            
            for (uint8 j; j < 4; j++) {

                Abrangencia storage abrangencia = eleicao.abrangencia[abrange[j]];

                for (uint16 k; k < eleicoes[i].cargos.length; k++) {

                    CargoInfo memory cargoQr = eleicoes[i].cargos[k];

                    uint8 idCargo = cargoQr.id;

                    if (idCargo == 0) { // resgata a identificação do cargo quando não há essa informação no início do conteúdo do QR Code
                        idCargo = bus[idHash].cp.cargo;
                    }

                    Cargo storage cargo = abrangencia.cargos[idCargo];
                    
                    if(cargo.info.id == 0) {
                        cargo.info.id = idCargo;
                    }

                    if (cargo.info.tipo == 0) {
                        cargo.info.tipo = cargoQr.tipo;
                    }
                    
                    cargo.info.aptos += cargoQr.aptos;
                    cargo.info.csec += cargoQr.csec;
                    cargo.info.nomi += cargoQr.nomi;
                    cargo.info.legc += cargoQr.legc;
                    cargo.info.branco += cargoQr.branco;
                    cargo.info.nulo += cargoQr.nulo;
                    cargo.info.totalVotosCargo += cargoQr.totalVotosCargo;

                    for (uint32 c; c < cargoQr.candidatos.length; c++) {
                        
                        uint128 localizacao = cargo.indiceCandidato[cargoQr.candidatos[c].id]; // 0 indica inexistência

                        if (localizacao == 0) { // verifica se o candidato já foi inserido

                            cargo.info.candidatos.push(cargoQr.candidatos[c]); // inserido no vetor na posição 0
                            cargo.indiceCandidato[cargoQr.candidatos[c].id] = uint128(cargo.info.candidatos.length); // o primeiro é inserido como posição 1, pois o mapping por default é 0 e, nesse caso, se um candidato não existir, retornaria sempre a primeira posição do vetor

                        } else {

                            cargo.info.candidatos[localizacao - 1].votos += cargoQr.candidatos[c].votos;

                        }
                    }

                    for (uint32 p; p < cargoQr.partidos.length; p++) {

                        uint32 idPartido = cargoQr.partidos[p].id;

                        if (idPartido == 0) { // resgata a identificação do partido quando não há essa informação no início do conteúdo do QR Code
                            idPartido = bus[idHash].cp.partido;
                        }

                        uint128 localizacao = cargo.indicePartido[idPartido]; // 0 indica inexistência

                        if (localizacao == 0) { // verifica se o partido já foi inserido

                            cargo.info.partidos.push(cargoQr.partidos[p]); // inserido no vetor na posição 0
                            cargo.indicePartido[idPartido] = uint128(cargo.info.partidos.length); // o primeiro é inserido como posição 1, pois o mapping por default é 0 e, nesse caso, se um partido não existir, retornaria sempre a primeira posição do vetor

                        } else {

                            cargo.info.partidos[localizacao - 1].votosLegenda += cargoQr.partidos[p].votosLegenda;
                            cargo.info.partidos[localizacao - 1].totalPartido += cargoQr.partidos[p].totalPartido;

                            for (uint32 cp; cp < cargoQr.partidos[p].candidatosPartido.length; cp++) {

                                cargo.info.partidos[localizacao - 1].candidatosPartido.push(cargoQr.partidos[p].candidatosPartido[cp]);

                            }
                        }                    
                    }
                }
            }
        }

        return true;
        
    }

    function obtemInfoTurno(uint128 idProc, uint8 idTurno) public view returns(uint8, uint32, uint32){
        uint128 localizacaoProcesso = indiceProcesso[idProc] - 1;
        return (listaProcessos[localizacaoProcesso].turnos[idTurno].id, listaProcessos[localizacaoProcesso].turnos[idTurno].pleito, listaProcessos[localizacaoProcesso].turnos[idTurno].dataPleito);
    }

    function obtemAbrangenciaUrna(string memory unfe, uint128 municipio, uint128 zona, uint128 secao) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(unfe, municipio, zona, secao));
    }

    function obtemAbrangenciaMunicipio(string memory unfe, uint128 municipio) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(unfe, municipio));
    }

    function obtemAbrangenciaUF(string memory unfe) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(unfe));
    }

    function obtemAbrangenciaNacional() public pure returns(bytes32) {
        return keccak256(abi.encodePacked("BR"));
    }
    
    function obtemCargo(uint128 idProc, uint8 idTurno, uint32 idEleicao, bytes32 abrangencia, uint8 idCargo) private view returns(Cargo storage){
        return listaProcessos[indiceProcesso[idProc] - 1].turnos[idTurno].eleicoes[idEleicao].abrangencia[abrangencia].cargos[idCargo];
    }
    
    function obtemResultadoGeral(uint128 idProc, uint8 idTurno, uint32 idEleicao, bytes32 abrangencia, uint8 idCargo) public view returns(CargoInfo memory){
        return obtemCargo(idProc, idTurno, idEleicao, abrangencia, idCargo).info;
    }
    
    function obtemVotosDoCandidato(uint128 idProc, uint8 idTurno, uint32 idEleicao, bytes32 abrangencia, uint8 idCargo, uint128 idCandidato) public view returns(Candidato memory){
        Cargo storage cargo = obtemCargo(idProc, idTurno, idEleicao, abrangencia, idCargo);
        uint128 indice = cargo.indiceCandidato[idCandidato] - 1;
        return cargo.info.candidatos[indice];
    }
    
    function obtemVotosDoPartido(uint128 idProc, uint8 idTurno, uint32 idEleicao, bytes32 abrangencia, uint8 idCargo, uint128 idPartido) public view returns(Partido memory){
        Cargo storage cargo = obtemCargo(idProc, idTurno, idEleicao, abrangencia, idCargo);
        uint128 indice = cargo.indicePartido[idPartido] - 1;
        return cargo.info.partidos[indice];
    }
    
    function obtemCandidatosDoPartido(uint128 idProc, uint8 idTurno, uint32 idEleicao, bytes32 abrangencia, uint8 idCargo, uint128 idPartido) public view returns(uint128[] memory){
        Cargo storage cargo = obtemCargo(idProc, idTurno, idEleicao, abrangencia, idCargo);
        uint128 indice = cargo.indicePartido[idPartido] - 1;
        return cargo.info.partidos[indice].candidatosPartido;
    }

    function obtemQRCode(bytes32 idBU, uint8 posicao) public view returns(QR memory) {
        return bus[idBU].qrs[posicao - 1];
    }

    function indiceListaProcesso(uint128 idProc) public view returns(uint128) {
        return indiceProcesso[idProc] - 1;
    }

}