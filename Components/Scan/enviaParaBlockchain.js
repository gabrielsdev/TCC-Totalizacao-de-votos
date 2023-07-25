import "react-native-get-random-values";

import "@ethersproject/shims";

const { ethers } = require("ethers");
const ABI = require('./abi.json');


const provider = new ethers.providers.JsonRpcProvider("http://137.117.69.211:8545");

const signer = new ethers.Wallet("dd77835d1dcb5ea769c187746a3b2df639d60aa056b0ea32ed26da9c887ced9b", provider);

const contract = new ethers.Contract("0x0452Ba0e7906c7a4fBC3909760F65a01dB9aa410", ABI.abi, provider);

const contractWithSigner = contract.connect(signer);


const registrar = async (idHash, qrcode) => {
    
    // let qrcode = "QRBU:1:2 VRQR:1.5 VRCH:20180618 ORIG:VOTA ORLC:LEG PROC:15000 DTPL:20181007 PLEI:15100 TURN:1 FASE:S UNFE:AC MUNI:1392 ZONA:9 SECA:16 AGRE:17.18.19.100 IDUE:1333898 IDCA:610860347874160324266426 VERS:6.28.2.1 LOCA:4 APTO:51 COMP:30 FALT:21 HBMA:0 DTAB:20181007 HRAB:173122 DTFC:20181007 HRFC:180755 IDEL:15103 CARG:6 TIPO:1 VERC:201807111207 PART:91 9101:1 9102:1 9103:1 9104:1 9105:1 LEGP:1 TOTP:6 PART:92 9201:1 9202:1 9203:1 9204:1 9205:1 LEGP:1 TOTP:6 PART:93 9301:1 9302:1 9303:1 9304:1 9305:1 LEGP:1 TOTP:6 PART:94 9401:1 9402:1 9403:1 9404:1 9405:1 LEGP:1 TOTP:6 PART:95 9501:1 9502:1 9503:1 9504:2 LEGP:1 TOTP:6 APTA:51 NOMI:25 LEGC:5 BRAN:0 NULO:0 TOTC:30 CARG:7 TIPO:1 VERC:201807111207 PART:91 91001:1 91002:1 91003:1 LEGP:3 TOTP:6 PART:92 92001:1 92002:1 92003:1 LEGP:3 TOTP:6 PART:93 93001:1 93002:1 93003:1 LEGP:3 TOTP:6 PART:94 94001:1 HASH:153DD1E96C876F062459DC9ACDF640D38BEBC4490C794826D8E7EB3CF4761BD39AFC560BAEF3895A9D3C59F16CDE61028DF07FED861234A0F91C7005AD94F797";

    let tokens = qrcode.split(/ /).map(n => n.trim());


    function BU(idHash, assinaturaParte1, assinaturaParte2, proc, turno, pleito, dataPleito, unfe, municipio, zona, secao, qrs, quantQrsEsperado, cp) {

        this.idHash = idHash;
        this.assinaturaParte1 = assinaturaParte1;
        this.assinaturaParte2 = assinaturaParte2;
        this.proc = proc;
        this.turno = turno;
        this.pleito = pleito;
        this.dataPleito = dataPleito;
        this.unfe = unfe;
        this.municipio = municipio;
        this.zona = zona;
        this.secao = secao;
        this.qrs = qrs;
        this.quantQrsEsperado = quantQrsEsperado;
        this.cp = cp;
    }

    function QR(posicao, qr) {
        this.posicao = posicao;
        this.qr = qr;
    }

    function CheckPoint(eleicao, cargo, partido) {
        this.eleicao = eleicao;
        this.cargo = cargo;
        this.partido = partido;
    }

    function Eleicoes(id, cargos) {
        this.id = id;
        this.cargos = cargos;
    }

    function CargoInfo(id, tipo, aptos, csec, nomi, legc, branco, nulo, totalVotosCargo, candidatos, partidos) {
        this.id = id;
        this.tipo = tipo;
        this.aptos = aptos;
        this.csec = csec;
        this.nomi = nomi;
        this.legc = legc;
        this.branco = branco;
        this.nulo = nulo;
        this.totalVotosCargo = totalVotosCargo;
        this.candidatos = candidatos;
        this.partidos = partidos;
    }

    function Candidato(id, votos) {
        this.id = id;
        this.votos = votos;
    }

    function Partido(id, votosLegenda, totalPartido, candidatosPartido) {
        this.id = id;
        this.votosLegenda = votosLegenda;
        this.totalPartido = totalPartido;
        this.candidatosPartido = candidatosPartido;
    }

    var bu = new BU(
        ethers.constants.HashZero, ethers.constants.HashZero, ethers.constants.HashZero, 0, 0, 0, 0, '', 0, 0, 0, [new QR(0, '')], 0, new CheckPoint(0, 0, 0)
    );

    var eleicoes = [];
    
    if (idHash == "") {
        idHash = ethers.constants.HashZero;
    }

    for (let i=0; i < tokens.length; i++) {

        let key = tokens[i].split(/:/).map(n => n.trim());

        switch (key[0]) {
            case 'QRBU': // marca o início do QR Code
                bu.qrs[0].posicao = parseInt(key[1]);
                bu.qrs[0].qr = qrcode;
                bu.quantQrsEsperado = parseInt(key[2]);
                break;

            case 'PROC':
                bu.proc = parseInt(key[1]);
                idHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(qrcode)); // PROC só aparece no primeiro QR Code
                break;

            case 'DTPL':
                bu.dataPleito = parseInt(key[1]);
                break;

            case 'PLEI':
                bu.pleito = parseInt(key[1]);
                break;

            case 'TURN':
                bu.turno = parseInt(key[1]);
                break;

            case 'UNFE':
                bu.unfe = key[1]; // string, exemplo: "RJ"
                break;

            case 'MUNI':
                bu.municipio = parseInt(key[1]);
                break;

            case 'ZONA':
                bu.zona = parseInt(key[1]);
                break;

            case 'SECA':
                bu.secao = parseInt(key[1]);
                break;

            case 'IDEL':
                eleicoes.push(new Eleicoes(parseInt(key[1]), []));
                bu.cp.eleicao = parseInt(key[1]); // último valor da eleição inserido para ser continuado no próximo QR Code
                break;

            case 'CARG':
                if (eleicoes.length == 0) {
                    eleicoes.push(new Eleicoes(0, []));
                }
                eleicoes[eleicoes.length - 1].cargos.push(new CargoInfo(parseInt(key[1]), 0, 0, 0, 0, 0, 0, 0, 0, [], []));
                bu.cp.cargo = parseInt(key[1]);
                break;

            case 'PART':
                if (eleicoes.length == 0) {
                    eleicoes.push(new Eleicoes(0, [new CargoInfo(0, 0, 0, 0, 0, 0, 0, 0, 0, [], [])]));
                }
                var posCargo = eleicoes[eleicoes.length - 1].cargos.length - 1;
                eleicoes[eleicoes.length - 1].cargos[posCargo].partidos.push(new Partido(parseInt(key[1]), 0, 0, []));
                bu.cp.partido = parseInt(key[1]);
                break;

            case 'LEGP':
            case 'TOTP':
                if (eleicoes.length == 0) {
                    eleicoes.push(new Eleicoes(0, [new CargoInfo(0, 0, 0, 0, 0, 0, 0, 0, 0, [], [new Partido(0, 0, 0, [])])]));
                }
                var posCargo = eleicoes[eleicoes.length - 1].cargos.length - 1;
                var tamPartido = eleicoes[eleicoes.length - 1].cargos[posCargo].partidos.length;

                if (tamPartido == 0) {
                    eleicoes[eleicoes.length - 1].cargos[posCargo].partidos.push(new Partido(0, 0, 0, []));
                    tamPartido += 1;
                }

                switch (key[0]) {
                    case 'LEGP':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].partidos[tamPartido - 1].votosLegenda = parseInt(key[1]);

                        var tamCandidatos = eleicoes[eleicoes.length - 1].cargos[posCargo].candidatos.length;
                        if (eleicoes[eleicoes.length - 1].cargos[posCargo].partidos[tamPartido - 1].id == 0 && tamCandidatos > 0) { // adiciona os primeiros candidatos do QR Code que não foram alocados a um partido
                            for (var c = 0; c < tamCandidatos; c++) {
                                eleicoes[eleicoes.length - 1].cargos[posCargo].partidos[tamPartido - 1].candidatosPartido.push(eleicoes[eleicoes.length - 1].cargos[posCargo].candidatos[c].id);
                            }
                        }
                        break;
                    case 'TOTP':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].partidos[tamPartido - 1].totalPartido = parseInt(key[1]);
                        break;
                }
                break;

            case 'TIPO':
            case 'APTA':
            case 'CSEC':
            case 'NOMI':
            case 'LEGC':
            case 'BRAN':
            case 'NULO':
            case 'TOTC':
                if (eleicoes.length == 0) {
                    eleicoes.push(new Eleicoes(0, [new CargoInfo(0, 0, 0, 0, 0, 0, 0, 0, 0, [], [])]));
                }
                var posCargo = eleicoes[eleicoes.length - 1].cargos.length - 1;

                switch (key[0]) {
                    case 'TIPO':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].tipo = parseInt(key[1]) + 1; // 0 indica inexistência
                        break;
                    case 'APTA':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].aptos = parseInt(key[1]);
                        break;
                    case 'CSEC':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].csec = parseInt(key[1]);
                        break;
                    case 'NOMI':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].nomi = parseInt(key[1]);
                        break;
                    case 'LEGC':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].legc = parseInt(key[1]);
                        break;
                    case 'BRAN':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].branco = parseInt(key[1]);
                        break;
                    case 'NULO':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].nulo = parseInt(key[1]);
                        break;
                    case 'TOTC':
                        eleicoes[eleicoes.length - 1].cargos[posCargo].totalVotosCargo = parseInt(key[1]);
                        break;
                }
                break;

            case 'ASSI':
                bu.assinaturaParte1 = "0x" + key[1].slice(0, 64);
                bu.assinaturaParte2 = "0x" + key[1].slice(64);
                break;

            default:
                bu.idHash = idHash; 
                if (!isNaN(parseInt(key[0]))) { // se o conteúdo for um inteiro
                    if (eleicoes.length == 0) {
                        eleicoes.push(new Eleicoes(0, [new CargoInfo(0, 0, 0, 0, 0, 0, 0, 0, 0, [], [])]));
                    }
                    var posCargo = eleicoes[eleicoes.length - 1].cargos.length - 1;
                    eleicoes[eleicoes.length - 1].cargos[posCargo].candidatos.push(new Candidato(parseInt(key[0]), parseInt(key[1])));
                    
                    var tamPartido = eleicoes[eleicoes.length - 1].cargos[posCargo].partidos.length;
                    if (tamPartido > 0) {
                        eleicoes[eleicoes.length - 1].cargos[posCargo].partidos[tamPartido - 1].candidatosPartido.push(parseInt(key[0]));
                    }
                }
        }

    }
    console.log(bu);
    console.log(eleicoes[0].cargos);
    const promise = await contractWithSigner.registrar(bu, eleicoes, {gasLimit: 800000000});
    const res = await promise.wait();
    return {idHash, res};
}

module.exports = registrar;