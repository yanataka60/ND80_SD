# ND8080又はND80Z3にSD-Cardとのロード、セーブ機能

シリアル同期通信によりND8080又はND80Z3とSD_ACCESS(ARDUINO+SD-CARD)とのロード、セーブを提供するルーチンです。


## 必要なもの
　27C256×1
 
　ピンヘッダ等
 
## 接続方法
Arduino　　　　　　　　　　ND8080 or ND80Z3

　　5V　　　　　　　-----　　5V　ND8080:CN4-9　ND80Z3:CN2-9
   
　　GND　　　　　　-----　　GND　ND8080:CN4-10　ND80Z3:CN2-10
   
　　9(FLG:output)　　　-----　　PC7(CHK:input)　ND8080:CN4-12　ND80Z3:CN2-12
             
　　8(OUT:output)　　-----　　PC5(IN:input)　ND8080:CN4-14　ND80Z3:CN2-14
                
　　7(CHK:input)　　　-----　　PC2(FLG:output)　ND8080:CN4-18　ND80Z3:CN2-18
                
　　6(IN :input)　　　　-----　　PC0(OUT:output)　ND8080:CN4-16　ND80Z3:CN2-16

## ROMの差し替え
　以下の製品版ROMバージョンで動作検証しています。

　ND8080 ROM1H

　ND80Z3 ROM4K

　共通して未使用となっていた領域は以下のとおりでここにルーチンを入れることで本来の機能は損なわないようにしています。

　　0E80H～0FFBH、1785H～17FFH、1EABH～1EFFH

　製品版ROMの内容を読み出し、バイナリエディタ等で以下のファイルの内容に修正します。

　　file_trans_ND80(0E80-0FF4).bin

　　file_trans_ND80(1790-17FE).bin

　　file_trans_ND80(1EB0-1EFC).bin

　TK80モード用ロード、セーブジャンプテーブルを修正します。(ND8080、ND80Z3共通)

　　0080～0083 7F->C4、04->0E、73->80、04->0E

　ZB3(Z80)モード用ロード、セーブジャンプテーブルを修正します。ND8080とND80Z3では場所が異なります。

　　ND8080　　　090D～0912 AE->1D、08->0F、47->C4、07->0E、69->80、07->0E

　　ND80Z3　　　08F7～08FC 98->1D、08->0F、47->C4、07->0E、69->80、07->0E

　すべての修正が終わったら用意したROMに焼き、装着します。

　製品版ROMは別途保管することをお勧めします。製品版ROMへの書き込みに失敗しても責任はとれません。

## 操作方法
　以下、xxxx:ファイルNo、ssss:スタートアドレス、eeee:エンドアドレスとします。

　異常が無いと思われるのにエラーとなってしまう場合にはSD-CardアダプタのArduinoとND8080又はND80Z3の両方をリセットしてからやり直してみてください。

### Save
　正常にSaveが完了するとアドレス部にスタートアドレス、データ部にエンドアドレスが表示されます。

　「FFFFFFFF」と表示された場合はSD-Card未挿入です。確認してください。

#### TK80 MODE時
　ファイルNo(xxxx)を4桁で入力して「*(I/O)」キーを押します。

　　　8000H～83C6Hまでをxxxx.BTKとしてセーブします。セーブ範囲は固定となっていて指定はできません。

#### ZB3(Z80) MODE時
二通りあります。

○　ファイルNo(xxxx)を4桁で入力して「*(I/O)」キー、次に「SO」キーを押します。

　　　8000H～83C6Hまでをxxxx.BTKとしてセーブします。セーブ範囲は固定となっていて指定はできません。

○　スタートアドレス(ssss)を4桁で入力して「ADRSSET」キー、エンドアドレス(eeee)を4桁で入力して「*(I/O)」キー、次に「PR(～OD)」キーを押してからファイルNo(xxxx)を4桁で入力します。

　　　ssssHからeeeeHまで(0000H～FFFFHまでの任意の範囲)をxxxx.BTKとしてセーブします。
### Load
　正常にLoadが完了するとアドレス部にスタートアドレス、データ部にエンドアドレスが表示されます。スタートアドレスが実行開始アドレスであればそのままRUNキーを押すことでプログラムが実行できます。

　「F0F0F0F0F0」と表示された場合はSD-Card未挿入、「F1F1F1F1F1」と表示された場合はファイルNoのファイルが存在しない場合です。確認してください。

#### TK80 MODE時

　ファイルNo(xxxx)を4桁で入力して「REG」キーを押します。

　　　xxxx.BTKをBTKヘッダ情報で示されたアドレスにロードします。ただし、83C7H～83FFH、FFB8H～FFFFHまでの範囲はライトプロテクトされます。

#### ZB3(Z80) MODE時

　ファイルNo(xxxx)を4桁で入力して「*(I/O)」キー、次に「SI」キーを押します。

　　　xxxx.BTKをBTKヘッダ情報で示されたアドレスにロードします。ただし、F800H～FFFFHまでの範囲はライトプロテクトされます。

## 扱えるファイル
　拡張子btkとなっているバイナリファイルです。
 
　ファイル名は0000～FFFFまでの16進数4桁を付けてください。(例:1000.btk)
 
　この16進数4桁がND8080又はND80Z3からSD-Card内のファイルを識別するファイルNoとなります。
 
　構造的には、バイナリファイル本体データの先頭に4バイトの開始アドレス、終了アドレスを付加した形になっています。
 
　パソコンのクロスアセンブラ等でND8080又はND80Z3用の実行binファイルを作成したらバイナリエディタ等で先頭に4バイトの開始アドレス、終了アドレスを付加し、ファイル名を変更したものをSD-Cardのルートディレクトリに保存すればND8080又はND80Z3から呼び出せるようになります。
