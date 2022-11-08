ドキュメントのURL https://www.kernel.org/doc/html/v4.12/driver-api/uio-howto.html

# memo
### UIOのメリット
① 極小のカーネルモジュールを書くだけで管理できる
② 開発の大部分をユーザー空間で行える。つまり、慣れ親しんだツールなどを用いてデバッグなどができる。
③ kernel crashが起きない。
④ カーネルの再コンパイルをしないでアップデートができる。

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
* 構造体uio_infoについて
```C
struct uo_info {
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
カーネルモジュール（サイズの小さなバイナリでカーネルの一部になるもの。後からの付け足しなどが可能）のロード・アンロードを行うコマンド
現在のデバイスドライバはカーネルに元々組み込んでおくものではなく、カーネルモジュールという小さな単位でロード・アンロードできる様にして管理されている。
内部ではinsmodを使用しているらしい。現在ロードされているモジュールを調べるにはlsmodコマンドが便利。
