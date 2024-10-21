version=0.9.4

# Check for bash shell
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

# Checking for root permission
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, but you need to run this script as root"
	exit 2
fi

# Cập nhật hệ thống và cài đặt các gói cần thiết
apt-get update && apt-get -y upgrade
apt-get install gcc make git -y

# Tải xuống và giải nén 3proxy từ kho lưu trữ GitHub
wget --no-check-certificate -O 3proxy-${version}.tar.gz https://github.com/z3APA3A/3proxy/archive/${version}.tar.gz
tar xzf 3proxy-${version}.tar.gz

# Dịch 3proxy
cd 3proxy-${version}
make -f Makefile.Linux

# Tạo thư mục và di chuyển tệp thực thi vào /etc/3proxy
cd src
mkdir -p /etc/3proxy/
mv ../bin/3proxy /etc/3proxy/

# Tải xuống tệp cấu hình và đặt quyền
cd /etc/3proxy/
wget --no-check-certificate https://github.com/thien-tn/3proxy/raw/master/3proxy.cfg
chmod 600 /etc/3proxy/3proxy.cfg

# Tạo thư mục log cho 3proxy
mkdir -p /var/log/3proxy/
wget --no-check-certificate https://github.com/thien-tn/3proxy/raw/master/.proxyauth
chmod 600 /etc/3proxy/.proxyauth

# Tải xuống tệp khởi động và thiết lập quyền cho script init.d
cd /etc/init.d/
wget --no-check-certificate https://raw.github.com/thien-tn/3proxy/master/3proxy
chmod +x /etc/init.d/3proxy

# Thiết lập 3proxy để khởi động cùng hệ thống
update-rc.d 3proxy defaults

# Tạo file menu tự động
cat <<EOT > /usr/local/bin/menu
#!/bin/bash
while true; do
    echo ""
    echo "Chọn một tùy chọn từ menu:"
    echo "1. Xem danh sách user hiện tại"
    echo "2. Thêm 1 user mới"
    echo "3. Thêm ngẫu nhiên nhiều user"
    echo "4. Xóa 1 user"
    echo "5. Xóa toàn bộ user"
    echo "6. Xóa toàn bộ cấu hình 3proxy"
    echo "7. Khởi động lại 3proxy server"
    echo "8. Thoát"
    echo ""
    read -p "Chọn một tùy chọn [1-8]: " choice
    echo ""
    
    case \$choice in
        1)
            echo "Danh sách user hiện tại:"
            cat /etc/3proxy/.proxyauth
            ;;
        2)
            read -p "Nhập tên user mới: " user
            read -p "Nhập mật khẩu cho user: " password
            echo "Thêm user $user"
            # Lệnh thêm user theo format Username:CL:Password
            echo "$user:CL:$password" >> /etc/3proxy/.proxyauth
            ;;
        3)
            read -p "Số lượng user muốn thêm ngẫu nhiên: " num
            echo "Thêm $num user ngẫu nhiên"
            for i in $(seq 1 $num); do
                # Tạo user ngẫu nhiên với 4 ký tự (gồm a-z, A-Z, 0-9)
                user="usr_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)"
                
                # Tạo password ngẫu nhiên với 4 ký tự (gồm a-z, A-Z, 0-9)
                password="pwd_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)"
                
                echo "Thêm user $user với password $password"
                
                # Lưu user và password theo format Username:CL:Password
                echo "$user:CL:$password" >> /etc/3proxy/.proxyauth
            done
            ;;
        4)
            read -p "Nhập tên user cần xóa: " user
            echo "Xóa user $user"
            sed -i "/^\$user:/d" /etc/3proxy/.proxyauth
            ;;
        5)
            echo "Xóa toàn bộ user"
            > /etc/3proxy/.proxyauth
            ;;
        6)
            echo "Xóa toàn bộ cấu hình 3proxy"
            rm -rf /etc/3proxy
            rm -rf /etc/init.d/3proxy
            rm -rf /var/log/3proxy
            grep -rl "3proxyinstall.sh" . | xargs rm -f
            ;;
        7)
            echo "Khởi động lại 3proxy server"
            /etc/init.d/3proxy restart
            ;;
        8)
            echo "Thoát"
            break
            ;;
        *)
            echo "Lựa chọn không hợp lệ, vui lòng chọn lại."
            ;;
    esac
done
EOT

# Cấp quyền thực thi cho file menu
chmod +x /usr/local/bin/menu

# Khởi động 3proxy server
echo "Khởi động 3proxy server"
/etc/init.d/3proxy start
