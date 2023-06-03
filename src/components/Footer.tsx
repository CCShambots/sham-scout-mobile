import React from "react";
import "./Footer.css"
import {Button, Icon} from "semantic-ui-react";



function Footer() {


    return(
        <div className={"header-container"}>

            <Button icon
                    size={"massive"}
                    color={"black"}
                    as={"a"}
                    href={"/#/matches"}
            >
                <Icon size={"huge"} name={"list"}/>
                <div className={"button-text"}>
                Matches
                </div>
            </Button>

            <Button icon
                    size={"massive"}
                    color={"black"}
                    as={"a"}
                    href={"/#/scan"}
            >
                <Icon size={"huge"} name={"qrcode"}/>
                <div className={"button-text"}>
                    Scan
                </div>
            </Button>

            <Button icon
                    size={"massive"}
                    color={"black"}
                    as={"a"}
                    href={"/"}
            >
                <Icon size={"huge"} name={"home"}/>
                <div className={"button-text"}>
                    Home
                </div>
            </Button>

            <Button icon
                    size={"massive"}
                    color={"black"}
                    as={"a"}
                    href={"/#/schedule"}
            >
                <Icon size={"huge"} name={"calendar alternate"}/>
                <div className={"button-text"}>
                    Schedule
                </div>
            </Button>

            <Button icon
                    size={"massive"}
                    color={"black"}
                    as={"a"}
                    href={"/#/settings"}
            >
                <Icon size={"huge"} name={"setting"}/>
                <div className={"button-text"}>
                    Settings
                </div>
            </Button>

        </div>
    )
}

export default Footer