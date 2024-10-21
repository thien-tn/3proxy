#!/usr/bin/env bash

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
    echo "6. Cài đặt lại 3proxy server"
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
            echo "Thêm user \$user"
            # Lệnh thêm user theo format Username:CL:Password
            echo "\$user:CL:\$password" >> /etc/3proxy/.proxyauth
            ;;
        3)
            read -p "Số lượng user muốn thêm ngẫu nhiên: " num
            echo "Thêm \$num user ngẫu nhiên"
            for i in \$(seq 1 \$num); do
                # Tạo user ngẫu nhiên với 4 ký tự (gồm a-z, A-Z, 0-9)
                user="usr_\$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)"
                
                # Tạo password ngẫu nhiên với 4 ký tự (gồm a-z, A-Z, 0-9)
                password="pwd_\$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)"
                
                echo "Thêm user \$user với password \$password"
                
                # Lưu user và password theo format Username:CL:Password
                echo "\$user:CL:\$password" >> /etc/3proxy/.proxyauth
            done
            ;;
        4)
            read -p "Nhập tên user cần xóa: " user
            echo "Xóa user \$user"
            sed -i "/^\$user:/d" /etc/3proxy/.proxyauth
            ;;
        5)
            echo "Xóa toàn bộ user"
            > /etc/3proxy/.proxyauth
            ;;
        6)
            # Xác nhận trước khi xóa cấu hình và cài đặt lại
            read -p "Bạn có chắc chắn muốn cài đặt lại 3proxy server? (y/n): " confirm
            if [ "\$confirm" = "y" ] || [ "\$confirm" = "Y" ]; then
                echo "Đang xóa cấu hình 3proxy..."
                /etc/init.d/3proxy stop
                rm -rf /etc/3proxy
                rm -rf /var/log/3proxy
                grep -rl "3proxyinstall.sh" . | xargs rm -f
                rm /etc/rc0.d/*proxy
                rm /etc/rc1.d/*proxy
                rm /etc/rc6.d/*proxy
                rm /etc/rc2.d/*proxy
                rm /etc/rc3.d/*proxy
                rm /etc/rc4.d/*proxy
                rm /etc/rc5.d/*proxy
                rm /etc/init.d/3proxy

                # Tải xuống và cài đặt lại 3proxy
                echo "Đang cài đặt lại 3proxy server..."
                wget https://raw.github.com/thien-tn/3proxy/master/3proxyinstall.sh -O 3proxyinstall.sh && bash 3proxyinstall.sh
            else
                echo "Hủy bỏ cài đặt lại 3proxy server."
            fi
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

# Tạo tệp proxy với định dạng IP:PORT:LOGIN:PASS
gen_proxy_file_for_user() {
    # Sử dụng một vòng lặp thông thường và redirect đầu ra vào tệp proxy.txt
    > proxy.txt  # Tạo hoặc làm trống tệp proxy.txt nếu nó đã tồn tại
    for i in $(seq 1 $numofproxy); do
        echo "$hostname:$port:${user[$i]}:${password[$i]}" >> proxy.txt
    done
}

install_zip_jq() {
    # install zip
    sudo apt-get install zip -y

    # install jq
    sudo apt-get install jq -y
}

# Nén tệp proxy và upload lên download server
upload_2file() {
    local PASS=$(openssl rand -base64 12)  # Tạo mật khẩu ngẫu nhiên
    zip --password "$PASS" proxy.zip proxy.txt
    JSON=$(curl -F "file=@proxy.zip" https://file.io)
    URL=$(echo "$JSON" | jq --raw-output '.link')

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"
}

# Output proxy list to console
hostname=$(hostname -I | awk '{print $1}')
echo "Proxy list (IP:PORT:LOGIN:PASS):"
for i in $(seq 1 $numofproxy); do
    if [[ -n "${user[$i]}" ]]; then
        echo "$hostname:$port:${user[$i]}:${password[$i]}"
    fi
done

# Tạo và upload tệp proxy
gen_proxy_file_for_user
install_zip_jq && upload_2file
