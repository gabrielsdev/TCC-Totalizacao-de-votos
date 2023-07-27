import React, { Component, Fragment } from 'react';
import { ScrollView, TouchableOpacity, Text, View, Image, ImageBackground } from 'react-native';
import QRCodeScanner from 'react-native-qrcode-scanner';
import Clipboard from '@react-native-clipboard/clipboard';
import styles from './scanStyle';
import registrar from './enviaParaBlockchain.js';

class Scan extends Component {
    constructor(props) {
        super(props);
        this.state = {
            scan: false,
            ScanResult: false,
            result: null,
            idHash: "",
            statusreceipt: false,
            resultSC: []
        };
    }
    onSuccess = async (e) => {
        const check = e.data.substring(0, 4);
        if(check != 'QRBU'){return}
        this.setState({
            result: e,
            scan: false,
            ScanResult: true
        })
        const {idHash, statusreceipt, res} = await registrar(this.state.idHash, e.data);
        console.log(statusreceipt);
        console.log(res);
        this.setState({
            idHash: idHash,
            result: e,
            scan: false,
            ScanResult: true,
            resultSC: res,
            statusreceipt: true
        })
    }
    activeQR = () => {
        this.setState({ scan: true, statusreceipt: false })
    }
    scanAgain = () => {
        this.setState({ scan: true, ScanResult: false })
    }
    home = () => {
        this.setState({ scan: false, ScanResult: false })
    }
    render() {
        const { scan, ScanResult, result, resultSC, statusreceipt } = this.state
        return (
            <View style={styles.scrollViewStyle}>
                <Fragment>
                    <View style={styles.header}>
                        <TouchableOpacity onPress={()=> this.home()}>
                            <Image source={require('../../assets/home.png')} style={{height: 36, width: 36}}></Image>
                        </TouchableOpacity>
                        <Text style={styles.textTitle}>Início</Text>
                    </View>
                    {!scan && !ScanResult &&
                        <View style={styles.cardView} >
                            <Image source={require('../../assets/camera.png')} style={{height: 36, width: 36}}></Image>
                            <Text numberOfLines={8} style={styles.descText}>Por favor, mova sua camêra {"\n"} sobre o QR Code</Text>
                            <Image source={require('../../assets/qr-code.png')} style={{margin: 20}}></Image>
                            <TouchableOpacity onPress={this.activeQR} style={styles.buttonScan}>
                                <View style={styles.buttonWrapper}>
                                <Image source={require('../../assets/camera.png')} style={{height: 36, width: 36}}></Image>
                                <Text style={{...styles.buttonTextStyle, color: '#2196f3'}}>Escanear QR Code</Text>
                                </View>
                            </TouchableOpacity>
                        </View>
                    }
                    {ScanResult &&
                        <ScrollView><Fragment>
                            <Text style={styles.textTitle1}>Leitura</Text>
                            <View style={ScanResult ? styles.scanCardView : styles.cardView}>
                                <Text>{result.data}</Text>
                                <TouchableOpacity onPress={() => Clipboard.setString(result.data)} style={styles.buttonScan}>
                                    <View style={styles.buttonWrapper}>
                                        <Text style={{...styles.buttonTextStyle, color: '#2196f3'}}>Copiar</Text>
                                    </View>
                                </TouchableOpacity>
                                <TouchableOpacity onPress={this.scanAgain} style={styles.buttonScan}>
                                    <View style={styles.buttonWrapper}>
                                        <Image source={require('../../assets/camera.png')} style={{height: 36, width: 36}}></Image>
                                        <Text style={{...styles.buttonTextStyle, color: '#2196f3'}}>Clique para escanear outro QR Code</Text>
                                    </View>
                                </TouchableOpacity>
                                
                            </View>
                            <Text style={styles.textTitle1}>Resultado</Text>
                            <View style={ScanResult ? styles.scanCardView : styles.cardView}>
                            {!statusreceipt &&
                                <Text>Totalizando...</Text>
                            }
                            {statusreceipt &&
                            
                                <Fragment>
                                    {resultSC.map(({ key, value }) => <Text>({[key]}: {value})</Text>)} 
                                </Fragment>
                            }
                            </View>
                        </Fragment>
                    </ScrollView>
                    }
                    {scan &&
                        <QRCodeScanner
                            reactivate={true}
                            showMarker={true}
                            ref={(node) => { this.scanner = node }}
                            onRead={this.onSuccess}
                            topContent={
                                <Text style={styles.centerText}>
                                   Por favor, mova sua camêra {"\n"} sobre o QR Code
                                </Text>
                            }
                            bottomContent={
                                <View>
                                    <ImageBackground source={require('../../assets/bottom-panel.png')} style={styles.bottomContent}>
                                        <TouchableOpacity style={styles.buttonScan2} 
                                            onPress={() => this.scanner.reactivate()} 
                                            onLongPress={() => this.setState({ scan: false })}>
                                            <Image source={require('../../assets/camera2.png')}></Image>
                                        </TouchableOpacity>
                                    </ImageBackground>
                                </View>
                            }
                        />
                    }
                </Fragment>
            </View>
        );
    }
}
export default Scan;