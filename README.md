gosu_examples_mieki256
======================

Ruby + Gosu examples.

Required library
----------------

    gem install gosu

Optional library
----------------

    gem install opengl
    gem install glu
    gem install glut


Gosuのゲームパッド対応状況について
----------------------------------

Gusuはキーボード入力に加えてゲームパッド入力にも対応しているが、ゲームパッド入力に関しては注意点がある。

Windows環境では利用できるUSBゲームパッド種類に制約がある。

- DirectInputタイプ(旧規格・安価)には非対応。
- XInputタイプ(新規格・高価)にのみ対応。

また、左右のアナログスティック・十字ボタンのどれを押しても8方向のデジタル入力として扱われる模様。

### USB接続ゲームパッドの動作確認状況

- ELECOM JC-U3613M (XInput) : OK (ドライバのインストールが必要)
- ELECOM JC-U3613M (DirectInput) : NG
- ELECOM JC-U2410TWH (DirectInput) : NG
- BUFFALO BSGP801GY (DirectInput) : NG

各製品の情報は以下。

- [Xinput対応ゲームパッド ELECOM JC-U3613MBK](http://www2.elecom.co.jp/products/JC-U3613MBK.html)
- [10ボタン配列USBゲームパッド ELECOM JC-U2410T](http://www2.elecom.co.jp/peripheral/gamepad/jc-u2410t/)
- [レトロ調USBゲームパッド 8ボタンタイプ - BUFFALO BSGP801GY](http://buffalo.jp/product/input/gamepad/bsgp801/)

