if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Index_Params {
    createCount?: number;
    result?: boolean;
    voiceInfo?: string;
    text?: string;
    textContent?: string;
    utteranceId?: string;
    originalText?: string;
    illegalText?: string;
}
import textToSpeech from "@hms:ai.textToSpeech";
import type { BusinessError } from "@ohos:base";
import hilog from "@ohos:hilog";
import { UuidBasic } from "@bundle:com.huawei.hms.ttsdemo/entry/ets/pages/UuidBasic";
import promptAction from "@ohos:promptAction";
const TAG: string = 'TtsDemo';
let ttsEngine: textToSpeech.TextToSpeechEngine;
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__createCount = new ObservedPropertySimplePU(0, this, "createCount");
        this.__result = new ObservedPropertySimplePU(false, this, "result");
        this.__voiceInfo = new ObservedPropertySimplePU("", this, "voiceInfo");
        this.__text = new ObservedPropertySimplePU("", this, "text");
        this.__textContent = new ObservedPropertySimplePU("", this, "textContent");
        this.__utteranceId = new ObservedPropertySimplePU("123456", this, "utteranceId");
        this.__originalText = new ObservedPropertySimplePU("\n\t\tThe ancients had no strength in learning, and the young were old and old. \n\t\t"
            + "They finally felt shallow on paper. They knew that this matter had to be done.\n\t\t", this, "originalText");
        this.__illegalText = new ObservedPropertySimplePU("", this, "illegalText");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
        if (params.createCount !== undefined) {
            this.createCount = params.createCount;
        }
        if (params.result !== undefined) {
            this.result = params.result;
        }
        if (params.voiceInfo !== undefined) {
            this.voiceInfo = params.voiceInfo;
        }
        if (params.text !== undefined) {
            this.text = params.text;
        }
        if (params.textContent !== undefined) {
            this.textContent = params.textContent;
        }
        if (params.utteranceId !== undefined) {
            this.utteranceId = params.utteranceId;
        }
        if (params.originalText !== undefined) {
            this.originalText = params.originalText;
        }
        if (params.illegalText !== undefined) {
            this.illegalText = params.illegalText;
        }
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__createCount.purgeDependencyOnElmtId(rmElmtId);
        this.__result.purgeDependencyOnElmtId(rmElmtId);
        this.__voiceInfo.purgeDependencyOnElmtId(rmElmtId);
        this.__text.purgeDependencyOnElmtId(rmElmtId);
        this.__textContent.purgeDependencyOnElmtId(rmElmtId);
        this.__utteranceId.purgeDependencyOnElmtId(rmElmtId);
        this.__originalText.purgeDependencyOnElmtId(rmElmtId);
        this.__illegalText.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__createCount.aboutToBeDeleted();
        this.__result.aboutToBeDeleted();
        this.__voiceInfo.aboutToBeDeleted();
        this.__text.aboutToBeDeleted();
        this.__textContent.aboutToBeDeleted();
        this.__utteranceId.aboutToBeDeleted();
        this.__originalText.aboutToBeDeleted();
        this.__illegalText.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __createCount: ObservedPropertySimplePU<number>;
    get createCount() {
        return this.__createCount.get();
    }
    set createCount(newValue: number) {
        this.__createCount.set(newValue);
    }
    private __result: ObservedPropertySimplePU<boolean>;
    get result() {
        return this.__result.get();
    }
    set result(newValue: boolean) {
        this.__result.set(newValue);
    }
    private __voiceInfo: ObservedPropertySimplePU<string>;
    get voiceInfo() {
        return this.__voiceInfo.get();
    }
    set voiceInfo(newValue: string) {
        this.__voiceInfo.set(newValue);
    }
    private __text: ObservedPropertySimplePU<string>;
    get text() {
        return this.__text.get();
    }
    set text(newValue: string) {
        this.__text.set(newValue);
    }
    private __textContent: ObservedPropertySimplePU<string>;
    get textContent() {
        return this.__textContent.get();
    }
    set textContent(newValue: string) {
        this.__textContent.set(newValue);
    }
    private __utteranceId: ObservedPropertySimplePU<string>;
    get utteranceId() {
        return this.__utteranceId.get();
    }
    set utteranceId(newValue: string) {
        this.__utteranceId.set(newValue);
    }
    private __originalText: ObservedPropertySimplePU<string>;
    get originalText() {
        return this.__originalText.get();
    }
    set originalText(newValue: string) {
        this.__originalText.set(newValue);
    }
    private __illegalText: ObservedPropertySimplePU<string>;
    get illegalText() {
        return this.__illegalText.get();
    }
    set illegalText(newValue: string) {
        this.__illegalText.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.height('100%');
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextArea.create({ placeholder: 'Please enter tts original text', text: `${this.originalText}` });
            TextArea.margin(20);
            TextArea.focusable(false);
            TextArea.border({ width: 5, color: 0x317AE7, radius: 10, style: BorderStyle.Dotted });
            TextArea.onChange((value: string) => {
                this.originalText = value;
                hilog.info(0x0000, TAG, "original text: " + this.originalText);
            });
        }, TextArea);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.createCount++;
                console.log(`createByCallback：createCount:${this.createCount}`);
                this.createByCallback();
                promptAction.showToast({
                    message: 'CreateEngine success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("CreateEngine");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.createCount++;
                console.log(`createByPromise：createCount:${this.createCount}`);
                this.createByPromise();
                promptAction.showToast({
                    message: 'CreateEngineByPromise success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("CreateEngineByPromise");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.createCount++;
                console.log(`createOfErrorLanguage：createCount:${this.createCount}`);
                this.createOfErrorLanguage();
                promptAction.showToast({
                    message: 'createOfErrorLanguage success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("createOfErrorLanguage");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.createCount++;
                console.log(`createOfErrorPerson：createCount:${this.createCount}`);
                this.createOfErrorPerson();
                promptAction.showToast({
                    message: 'createOfErrorPerson success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("createOfErrorPerson");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.createCount++;
                console.log(`speak：createCount:${this.createCount}`);
                this.speak();
                promptAction.showToast({
                    message: 'start speaking',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("speak");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.createCount++;
                console.log(`illegalSpeak：createCount:${this.createCount}`);
                this.illegalSpeak();
                promptAction.showToast({
                    message: 'SpeakIllegalText!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("SpeakIllegalText");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.listVoicesCallback();
                promptAction.showToast({
                    message: 'listVoicesCallback success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("listVoicesCallback");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                this.listVoicesPromise();
                promptAction.showToast({
                    message: 'listVoicesPromise success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("listVoicesPromise");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                hilog.info(0x0000, TAG, "isSpeaking click:-->");
                ttsEngine.stop();
                promptAction.showToast({
                    message: 'stop!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("stop");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AE7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                hilog.info(0x0000, TAG, "isSpeaking click:-->");
                this.setListener();
                let isBusy: boolean = ttsEngine.isBusy();
                console.log('isBusy :' + isBusy);
                if (isBusy) {
                    promptAction.showToast({
                        message: 'is busy!',
                        duration: 2000
                    });
                }
                else {
                    promptAction.showToast({
                        message: 'not busy',
                        duration: 2000
                    });
                }
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("isBusy");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.type(ButtonType.Capsule);
            Button.backgroundColor("#0x317AA7");
            Button.width("80%");
            Button.height(50);
            Button.margin(10);
            Button.onClick(() => {
                ttsEngine.shutdown();
                promptAction.showToast({
                    message: 'shutdown success!',
                    duration: 2000
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create("shutdown");
            Text.fontColor(Color.White);
            Text.fontSize(20);
        }, Text);
        Text.pop();
        Button.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    /*
    Create an engine, which is returned in callback mode
    If the engine does not exist, engine resources do not exist, or initialization times out,
    the error code 1002300005 is returned, indicating that the engine fails to be created
     */
    private createByCallback() {
        // Setting Engine Creation Parameters
        let extraParam: Record<string, Object> = { "style": 'interaction-broadcast', "locate": 'CN', "name": 'EngineName' };
        let initParamsInfo: textToSpeech.CreateEngineParams = {
            language: 'zh-CN',
            person: 0,
            online: 1,
            extraParams: extraParam
        };
        try {
            // Invoke the createEngine method
            textToSpeech.createEngine(initParamsInfo, (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
                if (!err) {
                    console.log('createEngine is success');
                    // Receive an instance of the creation engine
                    ttsEngine = textToSpeechEngine;
                }
                else {
                    /*
                    When an engine fails to be created, the error code 1002300005 is returned.
                    The possible causes are as follows: The engine does not exist, the resource does not exist,
                    or the engine creation times out.
                     */
                    console.error("errCode is " + JSON.stringify(err.code));
                    console.error("errMessage is " + JSON.stringify(err.message));
                }
            });
        }
        catch (error) {
            let message = (error as BusinessError).message;
            let code = (error as BusinessError).code;
            console.error(`createEngine failed, error code: ${code}, message: ${message}.`);
        }
    }
    // Create an engine, which is returned in promise mode
    private createByPromise() {
        // Setting Engine Creation Parameters
        let extraParam: Record<string, Object> = { "style": 'interaction-broadcast', "locate": 'CN', "name": 'EngineName' };
        let initParamsInfo: textToSpeech.CreateEngineParams = {
            language: 'zh-CN',
            person: 0,
            online: 1,
            extraParams: extraParam
        };
        // Invoke the createEngine method.
        textToSpeech.createEngine(initParamsInfo).then((res: textToSpeech.TextToSpeechEngine) => {
            ttsEngine = res;
            console.log('result:' + JSON.stringify(res));
        }).catch((res: Object) => {
            console.log('result' + JSON.stringify(res));
        });
    }
    /*
    Invoke the speak broadcast method.
    When the speak method is invoked before the engine is initialized,
    the error code 1002300007 is returned, indicating that the synthesis and playback fail.
     */
    private async speak() {
        // Set broadcast-related parameters.
        let extraParam: Record<string, Object> = {
            "queueMode": 0,
            "speed": 1,
            "volume": 2,
            "pitch": 1,
            "languageContext": 'zh-CN',
            "audioType": "pcm",
            "soundChannel": 1,
            "playType": 1
        };
        let speakParams: textToSpeech.SpeakParams = {
            requestId: UuidBasic.createUUID(),
            extraParams: extraParam
        };
        // Setting callbacks
        this.setListener();
        // Invoke the speak broadcast method.
        ttsEngine.speak(this.originalText, speakParams);
    }
    // This interface is used to query the timbre information of a language. The information is returned in callback mode.
    private listVoicesCallback() {
        // Set query-related parameters.
        let voicesQuery: textToSpeech.VoiceQuery = {
            requestId: UuidBasic.createUUID(),
            online: 1
        };
        // Invoke the listVoices method and return it as callback.
        ttsEngine.listVoices(voicesQuery, (err: BusinessError, voiceInfo: textToSpeech.VoiceInfo[]) => {
            if (!err) {
                // Receives information such as the timbre of the currently supported language.
                this.voiceInfo = JSON.stringify(voiceInfo);
                console.log('voiceInfo is ' + JSON.stringify(voiceInfo));
            }
            else {
                console.error("error is " + JSON.stringify(err));
            }
        });
    }
    // This interface is used to query the timbre information of a language. The information is returned in promise mode.
    private listVoicesPromise() {
        // Set query-related parameters.
        let voicesQuery: textToSpeech.VoiceQuery = {
            requestId: UuidBasic.createUUID(),
            online: 1
        };
        // Invoke the listVoice method.
        ttsEngine.listVoices(voicesQuery).then((res: textToSpeech.VoiceInfo[]) => {
            console.log('voiceInfo:' + JSON.stringify(res));
        }).catch((res: Object) => {
            console.error('error is ' + JSON.stringify(res));
        });
    }
    private setListener() {
        let speakListener: textToSpeech.SpeakListener = {
            // Start broadcast callback
            onStart(utteranceId: string, response: textToSpeech.StartResponse) {
                console.log('speakListener onStart: ' + ' utteranceId: ' + utteranceId + ' response: ' + JSON.stringify(response));
            },
            // Complete broadcast callback
            onComplete(utteranceId: string, response: textToSpeech.CompleteResponse) {
                console.log('speakListener onComplete: ' + ' utteranceId: ' + utteranceId + ' response: ' + JSON.stringify(response));
            },
            // Callback for stopping playback completion. This callback is triggered when the stop method is invoked and completed.
            onStop(utteranceId: string, response: textToSpeech.StopResponse) {
                console.log('speakListener onStop: ' + ' utteranceId: ' + utteranceId + ' response: ' + JSON.stringify(response));
            },
            // Return Audio Stream
            onData(utteranceId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
                console.log('speakListener onData: ' + ' utteranceId: ' + utteranceId + ' sequence: ' + JSON.stringify(response) + ' audio: ' + audio);
            },
            /*
            Error callback. This callback is triggered when an error occurs during playback.
            Error code 1002300007 is returned when the speak method is invoked when no engine is created,
            indicating that synthesis and playback fail.
            Invoke speak twice consecutively. If speak is invoked for the second time,
            the error code 1002300006 is returned, indicating that the service is busy.
             */
            onError(utteranceId: string, errorCode: number, errorMessage: string) {
                console.error('speakListener onError: ' + ' utteranceId: ' + utteranceId + ' errorCode: ' + errorCode + ' errorMessage: ' + errorMessage);
            }
        };
        // Setting callbacks
        ttsEngine.setListener(speakListener);
    }
    // When an engine is created in an unsupported language, the error code 1002300002 is returned,
    // indicating that the language is not supported.
    private createOfErrorLanguage() {
        // Setting Engine Creation Parameters
        let initParamsInfo: textToSpeech.CreateEngineParams = {
            // The language is not supported.
            language: 'ZH-CN',
            person: 0,
            online: 1
        };
        try {
            // Invoke the createEngine method.
            textToSpeech.createEngine(initParamsInfo, (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
                if (!err) {
                    console.log('createEngine is success');
                    // Receive an instance of the creation engine
                    ttsEngine = textToSpeechEngine;
                }
                else {
                    // The error code 1002300002 is returned. The language is not supported.
                    console.error("errCode is " + JSON.stringify(err.code));
                    console.error("errMessage is " + JSON.stringify(err.message));
                }
            });
        }
        catch (error) {
            let message = (error as BusinessError).message;
            let code = (error as BusinessError).code;
            console.error(`createEngine failed, error code: ${code}, message: ${message}.`);
        }
    }
    // When an engine is created in an unsupported language, the error code 1002300003 is returned,
    // indicating that the timbre is not supported.
    private createOfErrorPerson() {
        // Setting Engine Creation Parameters
        let initParamsInfo: textToSpeech.CreateEngineParams = {
            language: 'zh-CN',
            // Unsupported timbre
            person: 1,
            online: 1
        };
        try {
            // Invoke the createEngine method.
            textToSpeech.createEngine(initParamsInfo, (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
                if (!err) {
                    console.log('createEngine is success');
                    // Receive an instance of the creation engine
                    ttsEngine = textToSpeechEngine;
                }
                else {
                    // The error code 1002300003 is returned, indicating that the timbre is not supported.
                    console.error("errCode is " + JSON.stringify(err.code));
                    console.error("errMessage is " + JSON.stringify(err.message));
                }
            });
        }
        catch (error) {
            let message = (error as BusinessError).message;
            let code = (error as BusinessError).code;
            console.error(`createEngine failed, error code: ${code}, message: ${message}.`);
        }
    }
    // When invalid text is used, the speak broadcast method is invoked, and 1002300001 is returned.
    // The text length is invalid.
    private illegalSpeak() {
        this.setListener();
        // Set broadcast-related parameters.
        let extraParam: Record<string, Object> = { "speed": 1, "volume": 1, "pitch": 1, "audioType": "pcm" };
        let speakParams: textToSpeech.SpeakParams = {
            requestId: UuidBasic.createUUID(),
            extraParams: extraParam
        };
        // Invoke the speak broadcast method.
        ttsEngine.speak(this.illegalText, speakParams);
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.huawei.hms.ttsdemo", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
