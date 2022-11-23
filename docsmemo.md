ドキュメントのURL https://www.kernel.org/doc/html/v4.12/driver-api/uio-howto.html

# memo
### UIOのメリット
① 極小のカーネルモジュールを書くだけで管理できる
② 開発の大部分をユーザー空間で行える。つまり、慣れ親しんだツールなどを用いてデバッグなどができる。
③ kernel crashが起きない。
④ カーネルの再コンパイルをしないでアップデートができる。

## About UIO
- カードのUIOドライバを作成する場合、1つの小さなカーネルモジュールのみを使用しましょう。
### 動く仕組み
UIOデバイスは/dev/uio0のようなデバイスファイルといくつかのsysfs属性ファイルを通してアクセスされる。
/dev/uioXは、カードのアドレス空間にアクセスするために使用される。カードのレジスタやRAMの位置にアクセスするには、mmapを用いれば良い。
/dev/uioXファイルからreadすると、デバイスの割り込み発生時に、帰ってくる。
readの返り値nは割り込みの数を表しており、いくつかの割り込みを見落としたかが分かるようになっている。

/sys/class/uio/uioX/配下に色々創られるらしい。
UIOデバイスが使用するメモリのマッピングは、このディレクトリの配下の/sys/class/uio/uioX/maps/map0/のような独自のディレクトリを持つ。
各mapXディレクトリは、メモリの属性を示す4つの読み取り専用ファイルが含まれる。
* name: このマッピングの識別子。
* addr: マップ可能なメモリのアドレス。
* size: addrが指し示すメモリのサイズ。
* offset: mmap()からの返り値に加算する値（bytes）。デバイスのメモリがページサイズにアラインメントされていない場合に重要！！

メモリ以外にも、ioportに直接書き込む必要がある時もある。その場合は、/sys/class/uio/uioX/portio/というディレクトリがある。この配下のサブディレクトリの命名規則もportXのような感じになっている。
この場合もname, start, size, porttypeといった読み取り専用ファイルが存在している。

### カーネルモジュールの作成方法
以降の説明は、uio_cif.cファイル内のものの説明である。
* 構造体uio_infoについて
```C
struct uio_info {
    const char *name; // ドライバの名前（必須）
    const char *version; // /sys/class/uio/uioX/versionに表示される
    struct uio_mem mem[MAX_UIO_MAPS]; // メモリのマッピングごとに一つの構造体が必要
    struct uio_port port[MAX_UIO_PORTS_REGIONS] // ioportに関する情報をユーザー空間に渡したい場合は必要
    long irq; // 必須。UIOデバイスが割り込みを発生させた時にその割り込みのIRQ番号を指定するのはモジュールの役割。
    unsigned long irq_flags; // ハードウェア割り込みを発生させる場合は必須。
    int (*mmap)(struct uio_info *info, struct vm_area_struct *vma); // mmapは独自のものを使用するように設定できる。この値が0の場合、デフォルトのmmapが呼ばれる
    int (*open)(struct uio_info *info, struct inode *inode);
    int (*release)(struct uio_info *info, struct inode *inode);
    int (*irqcontrol)(struct uio_info *info, s32 irq_on);
};
```
基本的にデバイスにはユーザー空間にマップするメモリ領域が少なくとも１つ存在するので、mem[]配列は一つ以上の要素を持つ。各要素が取る構造は以下のようなもの。

```C
struct uio_mem {
    const char *name; // sysfsノードで表示される。
    int memtype; // これはマッピングされた領域がどんな種類のものなのかを示す。実際のカード上の物理メモリにマップされた場合はUIO_MEM_PHYSを、論理メモリの場合はUIO_MEM_LOGICALを、仮想メモリも場合はUIO_MEM_VIRTUALをここに指定する。
    phys_addr_t addr; // メモリブロックのアドレスを記入。
    resource_size_t size; // メモリブロックの数を記入。
    void *internal_addr;
};
// この構造体のmapメンバには触れないこと！（とりあえず従っておこう）
```
ポートの管理はstruct uio_portで行うらしい。ここは一旦割愛する。。。



### 割り込みハンドラについて
ハードウェアからの割り込みの後に何か実行する必要がある場合は、カーネルモジュールで実行する必要がある。ユーザー空間上のドライバに依存してはならない。



### modprobeコマンド
カーネルモジュール（サイズの小さなバイナリでカーネルの一部になるもの。後からの付け足しなどが可能）のロード・アンロードを行うコマンド。
現在のデバイスドライバはカーネルに元々組み込んでおくものではなく、カーネルモジュールという小さな単位でロード・アンロードできる様にして管理されている。
内部ではinsmodを使用しているらしい。現在ロードされているモジュールを調べるにはlsmodコマンドが便利。

## Writing a driver in userspace
開発するドライバのユーザー空間側のコードは、基本何を使ってもいいらしい。例えば、ライブラリとか。本当に普通のアプリとして開発ができるらしい！！！


### Getting information about your UIO device
UIOデバイスに関する情報は、sysfsに全てある。
ドライバがまず最初にやらなければならないことは、nameとversionの確認である。
また、必要なメモリマップの場所や大きさも確認して置く必要がある。

以上のことを設定したら、mmapで対象のメモリ領域をユーザー空間にマップする。
mmapのパラメーターoffsetに関しては、、、、（後で）

mmapによってマップされたメモリ領域へは通常の配列のようにアクセスが可能になる。
After that, your hardware starts working and will generate an interrupt as soon as it’s finished, has some data available, or needs your attention because an error occurred.
このアクセスにより初期化を完了すれば、デバイスは動き始める。
動作が終了したりしたら、割り込みを発生させる。
/dev/uioXというファイルは、Read−Onlyなファイルで、このファイルを通して割り込みは通達される。
ユーザー空間のドライバは、このファイルをread()することで、デバイスから割り込みが来るまで、ブロックされる。

## Generic PCI UIO driver
これは、uio_pci_genericというカーネルモジュールで、PCI2.3/PCI Expressに準拠したデバイスならば動作する。
このモジュールを使うことで、ドライバ開発者はユーザー空間の部分のみのコードを書くだけでよくなる。
（カーネルモジュール自体を書く必要がなくなる）

#### デバイスを検出するドライバの作成
このモジュールは自動的にロードされたり、デバイスをバインドしたりはせず、
使用する際は開発者が自分でロードしてドライバにデバイスのIDを割り当てる必要がある。
```
modprobe uio_pci_generic
echo "8086 10f5" > /sys/bus/pci/drivers/uio_pci_generic/new_id
```
既にカーネルドライバが存在しているデバイスに関しては、自動でバインドすることはない。
もし、現在使用中のドライバをアンバインドしたい場合は、そのような操作をする必要がある。
```
echo -n 0000:00:19.0 > /sys/bus/pci/drivers/e1000e/unbind
echo -n 0000:00:19.0 > /sys/bus/pci/drivers/uio_pci_generic/bind
```
デバイスがどのドライバに接続されているのかは、以下のコマンドで検証できる。
以下は不揮発性ストレージの場合。
```
ls -l /sys/bus/pci/devices/0000\:01:00.0/driver
```
## Things to know about uio_pci_generic
割り込みに関しては、PCI Configuration SpaceのCommand RegisterのInterrupt Disable BitとInterrupt Statusで管理される。
このモジュールは、Command RegisterのInterrupt Disable Bitをサポートしていないデバイスのマップをしないので注意。
