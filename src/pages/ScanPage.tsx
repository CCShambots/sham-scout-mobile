import React, {useState} from "react";
import Footer from "../components/Footer";

import QrReader from "react-qr-scanner"
import "./ScanPage.css"

function ScanPage() {

    let [result, setResult] = useState("None detected!")

    let handleScan = (data:any) => {
        if(data) {
            setResult(data.text)
        }
    }

    return (
        <div className={"App"}>
            <Footer/>

            <h1>Scan a Code</h1>

            <div className={"camera-container"}>
                <QrReader
                    onError={() => console.log("error :(")}
                    onScan={handleScan}
                />
            </div>

            <h6>{result}</h6>
        </div>
    )
}

export default ScanPage