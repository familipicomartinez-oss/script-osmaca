#!/bin/bash
# Verificación de compatibilidad con sistemas basados en Debian/Ubuntu
if [ ! -f /etc/os-release ]; then
    echo "Sistema no compatible con este instalador."
    exit 1
fi

C='\033[0;36m'; V='\033[1;32m'; A='\033[1;33m'; R='\033[1;31m'; N='\033[0m'; M='\033[1;35m'
IP_VPS=$(hostname -I | awk '{print $1}'); [ -z "$IP_VPS" ] && IP_VPS="Desconocida"
es() { systemctl is-active --quiet $1 && echo -e "${V}[ON] ${N}" || echo -e "${R}[OFF]${N}"; }
ep() { ss -tlnp | grep -q ":$1 " > /dev/null 2>&1 || ss -ulnp | grep -q ":$1 " > /dev/null 2>&1 && echo -e "${V}[ON] ${N}" || echo -e "${R}[OFF]${N}"; }

info_sistema() {
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USADA=$(free -m | awk '/Mem:/ {print $3}')
    LIBRE_RAM=$(free -m | awk '/Mem:/ {print $4}')
    PORCENT_RAM=$(( (MEM_USADA * 100) / MEM_TOTAL ))
    S_OS=$(grep -oP '(?<=PRETTY_NAME=")[^"]+' /etc/os-release 2>/dev/null || echo "Linux System")
    S_ARCH=$(uname -m)
    S_CPU=$(nproc)
    FECHA_ACT=$(date +'%d/%m/%Y-%H:%M')
    
    STR_PORTS=""
    C_PORT=0
    agregar_puerto() {
        STR_PORTS+="$1       "
        C_PORT=$((C_PORT+1))
        if [ $C_PORT -eq 2 ]; then
            STR_PORTS+="\n "
            C_PORT=0
        fi
    }
    
    ss -tlnp | grep -q ":22 " && agregar_puerto "🔹 SSH: ${V}22${N}"
    ss -tlnp | grep -q ":80 " && agregar_puerto "🔹 PROXY: ${V}80${N}"
    ss -tlnp | grep -q ":443 " && agregar_puerto "🔹 SSL: ${V}443${N}"
    ss -tlnp | grep -q ":444 " && agregar_puerto "🔹 SSL: ${V}444${N}"
    ss -ulnp | grep -q ":36712 " && agregar_puerto "🔹 UDP: ${V}36712${N}"
    ss -tlnp | grep -q ":53 " && agregar_puerto "🔹 DNS: ${V}53${N}"
    ss -ulnp | grep -q ":7300 " && agregar_puerto "🔹 BadVPN: ${V}7300${N}"
    ss -ulnp | grep -q ":7200 " && agregar_puerto "🔹 BadVPN: ${V}7200${N}"
    
    [ -z "$STR_PORTS" ] && STR_PORTS="🔹 ${R}Sin puertos abiertos actualmente${N}"

    echo -e "${C}=========>>>>> 🌿 Script Osmaca 🌿 <<<<<=========${N}"
    echo -e "${V}$IP_VPS${N}"
    echo -e "${A}────────────────────────────────────────────────────────${N}"
    echo -e " 🔹 S.O: ${C}$S_OS${N}  🔹 Base:${C}$S_ARCH${N}  🔹 CPU's:${C}$S_CPU${N}"
    echo -e " 🔹 IP:  ${V}$IP_VPS${N}  🔹 FECHA: ${A}$FECHA_ACT${N}"
    echo -e "${A}────────────────────────────────────────────────────────${N}"
    echo -e " Key: ${V}Verified [ Sabana de Torres © ] (V5.6)${N}"
    echo -e "${A}────────────────────────────────────────────────────────${N}"
    echo -e " ${M}🟢 PUERTOS ACTIVOS:${N}"
    echo -e " $STR_PORTS"
    echo -e "${A}────────────────────────────────────────────────────────${N}"
    echo -e " 🔹 TOTAL: ${C}${MEM_TOTAL}M${N} 🔹 M|LIBRE: ${C}${LIBRE_RAM}M${N} 🔹 EN USO: ${C}${MEM_USADA}M${N}"
    echo -e " 🔹 U/RAM: ${A}${PORCENT_RAM}%${N}"
    echo -e "${A}────────────────────────────────────────────────────────${N}"
}

menu_usuarios() {
    while true; do
        clear
        echo -e "${C}================================================${N}"
        echo -e "       ${A}⚜️  CREADOR DE CUENTAS TIPO ⚜️${N}"
        echo -e "       ${C}MENU DE CREACION DE USUARIOS${N}"
        echo -e "${C}================================================${N}"
        echo -e " [1] ➕ CREAR USUARIO SSH"
        echo -e " [2] 🗑️  ELIMINAR USUARIO"
        echo -e " [3] 👥 VER LISTADO DE USUARIOS"
        echo -e " [0] ↩️  VOLVER"
        read -p " ► Opcion: " op_user
        case $op_user in
            1) 
               clear
               echo -e "${C}================================================${N}"
               echo -e "       ${A}⚜️  CREADOR DE CUENTAS TIPO ⚜️${N}"
               echo -e "${C}================================================${N}"
               read -p " 👤 Nombre de usuario: " u
               read -p " 🔑 Contraseña: " p
               read -p " ⏳ Dias de duración: " d
               read -p " 📈 Límite de conexiones: " l
               
               useradd -m -s /bin/bash "$u" 2>/dev/null
               echo "$u:$p" | chpasswd 2>/dev/null
               chage -E $(date -d "+$d days" +%Y-%m-%d) "$u" 2>/dev/null || true
               
               mkdir -p /etc/vps_limites
               echo "$l" > "/etc/vps_limites/$u"
               
               if [ ! -f /usr/local/bin/monitor_limites.sh ]; then
cat << 'EOF_MONITOR' > /usr/local/bin/monitor_limites.sh
#!/bin/bash
for user in \$(ls /etc/vps_limites/ 2>/dev/null); do
    limite=\$(cat /etc/vps_limites/\$user)
    conex=\$(ps -u \$user 2>/dev/null | grep -c sshd)
    if [ "\$conex" -gt "\$limite" ]; then
        pkill -u \$user sshd
    fi
done
EOF_MONITOR
                   chmod +x /usr/local/bin/monitor_limites.sh
                   (crontab -l 2>/dev/null | grep -v "monitor_limites.sh"; echo "* * * * * /usr/local/bin/monitor_limites.sh") | crontab -
               fi

               apt-get install figlet -y >/dev/null 2>&1
               clear
               echo -e "${C}================================================${N}"
               if command -v figlet > /dev/null 2>&1; then
                   echo -e "${V}$(figlet -c -f slant "$u")${N}"
               else
                   echo -e "${V}     >>> $u <<<     ${N}"
               fi
               echo -e "${C}* Puertas Activas en su Servidor *${N}"
               echo -e "${A}────────────────────────────────────────────────────────${N}"
               
               STR_P=""
               ss -tlnp | grep -q ":22 " && STR_P+="🔹 SSH: ${V}22${N}   "
               ss -tlnp | grep -q ":80 " && STR_P+="🔹 PROXY: ${V}80${N}   "
               ss -tlnp | grep -q ":443 " && STR_P+="🔹 SSL: ${V}443${N}   "
               ss -ulnp | grep -q ":36712 " && STR_P+="🔹 UDP: ${V}36712${N}   "
               [ -z "$STR_P" ] && STR_P="🔹 ${R}Sin puertos configurados${N}"
               echo -e " $STR_P"
               
               echo -e "${A}────────────────────────────────────────────────────────${N}"
               echo -e " Host/IP-Address : ${V}$IP_VPS${N}"
               echo -e " USUARIO : ${V}$u${N}"
               echo -e " PASSWD  : ${V}$p${N}"
               echo -e " LIMITE  : ${V}$l${N}"
               echo -e " VALIDEZ : ${V}$(date -d "+$d days" +%d/%m/%Y)${N}"
               echo -e "${A}────────────────────────────────────────────────────────${N}"
               echo -e " ${R}✓ El servidor desconectará automáticamente al${N}"
               echo -e " ${R}  usuario si supera el límite de $l conexiones.${N}"
               echo -e "${C}================================================${N}"
               read -p " ► Enter para continuar..." ;;
            2) read -p " Usuario a eliminar: " u; userdel -r "$u" 2>/dev/null && rm -f /etc/vps_limites/$u && echo -e "${V}Eliminado.${N}" || echo -e "${R}Error.${N}"; read -p "Enter..." ;;
            3) awk -F: '$3 >= 1000 && $1 != "nobody" {print " -> " $1}' /etc/passwd; read -p "Enter..." ;;
            0) break ;;
        esac
    done
}

menu_ssl() {
    while true; do
        clear
        echo -e "${A}--- GESTOR DE PROTOCOLO SSL/TLS ---${N}"
        echo -e " Estado: $(es stunnel4)"
        echo -e "----------------------------------------"
        echo -e " ${V}[1]${N} 🟢 Instalar Certificado SSL (Interno 22 -> Externo a elegir)"
        echo -e " ${A}[2]${N} ⏸️  Detener SSL"
        echo -e " ${R}[3]${N} 🗑️  Desinstalar"
        echo -e " ${C}[0]${N} ↩️  Volver"
        echo -e "----------------------------------------"
        read -p " ► Opcion : " op_ssl
        case $op_ssl in
            1) 
               p1=22
               read -p " ► Puerto externo SSL a elegir (Ej: 443, 444): " p2; p2=${p2:-443}
               apt-get update >/dev/null 2>&1
               apt-get install stunnel4 openssl -y >/dev/null 2>&1
               openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem -subj "/CN=Sabana/O=VPN/C=CO" >/dev/null 2>&1
               echo -e "pid = /var/run/stunnel4.pid\ncert = /etc/stunnel/stunnel.pem\nclient = no\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n[stunnel-custom]\naccept = $p2\nconnect = 127.0.0.1:$p1" > /etc/stunnel/stunnel.conf
               sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null || echo "ENABLED=1" > /etc/default/stunnel4
               ufw allow $p2/tcp >/dev/null 2>&1
               systemctl restart stunnel4
               echo -e "${V}¡SSL instalado y activo en puerto externo $p2!${N}"
               read -p "Enter..." ;;
            2) systemctl stop stunnel4; echo -e "${A}Detenido.${N}"; read -p "Enter..." ;;
            3) systemctl stop stunnel4; apt-get purge stunnel4 -y >/dev/null 2>&1; rm -rf /etc/stunnel/; echo -e "${R}Desinstalado.${N}"; read -p "Enter..." ;;
            0) break ;;
        esac
    done
}

menu_py() {
    while true; do
        clear
        echo -e "${A}--- GESTOR DE PROXY PYTHON ---${N}"
        echo -e " Estado: $(es proxypy)"
        echo -e "----------------------------------------"
        echo -e " ${V}[3]${N} 🟢 WebSocket PRO (Elegir Puerto)"
        echo -e " ${A}[4]${N} ⏸️  Detener Proxy"
        echo -e " ${R}[5]${N} 🗑️  Desinstalar"
        echo -e " ${C}[0]${N} ↩️  Volver"
        echo -e "----------------------------------------"
        read -p " ► Opcion : " op_py
        case $op_py in
            3) 
               read -p " ► Puerto para el WebSocket (Ej: 80): " pt; pt=${pt:-80}
               echo -e "${A}Liberando el puerto $pt y preparando Python...${N}"
               systemctl stop apache2 nginx dropbear 2>/dev/null
               fuser -k $pt/tcp 2>/dev/null
               apt-get update >/dev/null 2>&1
               apt-get install python3 -y >/dev/null 2>&1
               
cat << 'EOF_PY' > /etc/proxy.py
import socket, threading
def c(s):
    try:
        s.recv(1024)
        s.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
        d = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        d.connect(('127.0.0.1', 22))
        def f(x, y):
            try:
                while True:
                    a = x.recv(4096)
                    if not a: break
                    y.sendall(a)
            except: pass
        threading.Thread(target=f, args=(s, d)).start()
        threading.Thread(target=f, args=(d, s)).start()
    except: pass
sv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sv.bind(('0.0.0.0', PUERTO_AQUI))
sv.listen(100)
while True:
    cl, a = sv.accept()
    threading.Thread(target=c, args=(cl,)).start()
EOF_PY

               sed -i "s/PUERTO_AQUI/$pt/g" /etc/proxy.py
               echo -e "[Unit]\nDescription=Proxy Python WS\n[Service]\nExecStart=/usr/bin/python3 /etc/proxy.py\nRestart=always\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/proxypy.service
               systemctl daemon-reload; systemctl enable proxypy >/dev/null 2>&1; systemctl restart proxypy
               ufw allow $pt/tcp >/dev/null 2>&1
               echo -e "${V}¡WebSocket PRO Activo en el puerto $pt!${N}"
               read -p "Enter..." ;;
            4) systemctl stop proxypy; echo -e "${A}Detenido.${N}"; read -p "Enter..." ;;
            5) systemctl stop proxypy; rm -f /etc/proxy.py /etc/systemd/system/proxypy.service; systemctl daemon-reload; echo -e "${R}Desinstalado.${N}"; read -p "Enter..." ;;
            0) break ;;
        esac
    done
}

menu_udp() {
    while true; do
        clear
        echo -e "${A}--- UDP CUSTOM ---${N}"
        echo -e " Estado: $(es udp-custom)"
        echo -e "----------------------------------------"
        echo -e " ${V}[1]${N} 🟢 Instalar UDP Custom"
        echo -e " ${A}[2]${N} ⏸️  Detener UDP"
        echo -e " ${R}[3]${N} 🗑️  Desinstalar UDP"
        echo -e " ${C}[0]${N} ↩️  Volver"
        echo -e "----------------------------------------"
        read -p " ► Opcion : " op_udp
        case $op_udp in
            1) 
               echo "Instalando servidor UDP Custom..."
               apt-get update >/dev/null 2>&1
               apt-get install -y iptables wget >/dev/null 2>&1
               wget -q "https://raw.githubusercontent.com/Haris131/UDP-Custom/main/udp-custom-linux-amd64" -O /usr/bin/udp-custom
               chmod +x /usr/bin/udp-custom; mkdir -p /root/udp
               echo -e "{\n  \"listen\": \":36712\",\n  \"stream_buffer\": 33554432,\n  \"receive_buffer\": 8388608,\n  \"auth\": {\n    \"mode\": \"passwords\"\n  }\n}" > /root/udp/config.json
               echo -e "[Unit]\nDescription=UDP Custom\n[Service]\nUser=root\nType=simple\nWorkingDirectory=/root/udp\nExecStart=/usr/bin/udp-custom server -exclude 53,5300,443\nRestart=always\nRestartSec=2\n[Install]\nWantedBy=default.target" > /etc/systemd/system/udp-custom.service
               systemctl daemon-reload; systemctl enable udp-custom >/dev/null 2>&1; systemctl restart udp-custom
               iptables -t nat -D PREROUTING -p udp --dport 1:65535 -j REDIRECT --to-ports 36712 2>/dev/null
               iptables -t nat -A PREROUTING -p udp --dport 1:65535 -j REDIRECT --to-ports 36712
               echo -e "${V}¡UDP Custom Instalado y Activo!${N}"
               read -p "Enter..." ;;
            2) systemctl stop udp-custom; echo -e "${A}Detenido.${N}"; read -p "Enter..." ;;
            3) systemctl stop udp-custom; rm -rf /usr/bin/udp-custom /root/udp /etc/systemd/system/udp-custom.service; systemctl daemon-reload; iptables -t nat -D PREROUTING -p udp --dport 1:65535 -j REDIRECT --to-ports 36712 2>/dev/null; echo -e "${R}Desinstalado.${N}"; read -p "Enter..." ;;
            0) break ;;
        esac
    done
}

menu_badvpn() {
    while true; do
        clear
        P_BAD72=$(ss -ulnp | grep -q ":7200 " && echo -e "${V}[ON]${N}" || echo -e "${R}[OFF]${N}")
        P_BAD73=$(ss -ulnp | grep -q ":7300 " && echo -e "${V}[ON]${N}" || echo -e "${R}[OFF]${N}")
        
        echo -e "${A}--- BADVPN UDP (VIDEOLAMADAS) ---${N}"
        echo -e " Estado: 7200 $P_BAD72 | 7300 $P_BAD73"
        echo -e "----------------------------------------"
        echo -e " ${V}[1]${N} 🟢 Instalar BadVPN (7200 y 7300)"
        echo -e " ${A}[2]${N} ⏸️  Detener BadVPN"
        echo -e " ${R}[3]${N} 🗑️  Desinstalar BadVPN"
        echo -e " ${C}[0]${N} ↩️  Volver"
        echo -e "----------------------------------------"
        read -p " ► Opcion : " op_badvpn
        case $op_badvpn in
            1) 
               clear
               echo -e "${A}────────────────────────────────────────────${N}"
               echo -e "${A}                 NOTA !!                    ${N}"
               echo -e "${A}────────────────────────────────────────────${N}"
               echo -e "${R} BADVPN UDP SE INSTALARA EN EL SISTEMA${N}"
               echo -e "${R} PROTOCOLO UDP QUE LIBERA EL SERVICIO DE${N}"
               echo -e "${R} VIDEOLLAMADAS Y JUEGOS EN LINEA${N}"
               echo -e "${A}────────────────────────────────────────────${N}"
               echo -e "${C}             INICIANDO . . .                ${N}"
               echo -e "${A}────────────────────────────────────────────${N}"
               echo -e "${C} FUNCION REDISEÑADA HABILITARA EL PUERTO 7300 EN BADVPN-UDP${N}"
               echo -e "${C} ADICIONAL APERTURAREMOS EL 7200 PARA UN DUAL CHANNEL${N}"
               echo -e "${C} PROCURA ALTERNAR LOS PUERTOS EN LAS APPS${N}"
               echo -e "${C} PARA UNA EXPERIENCIA LIGERA Y SIN CORTES DE LLAMADAS${N}"
               echo -e ""
               echo -n -e "Buscando Binario BadVPN e SWAP..."
               
               apt-get update >/dev/null 2>&1
               apt-get install cmake make gcc wget -y >/dev/null 2>&1
               wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premiumsript8/master/badvpn-udpgw64"
               chmod +x /usr/bin/badvpn-udpgw
               
               echo -e "${V}Ok${N}"
               echo -e "${A}────────────────────────────────────────────${N}"
               echo -e "${V}           ACTIVADO CON EXITO               ${N}"
               echo -e "${A}────────────────────────────────────────────${N}"
               echo -e "${A} PREGUNTA PREVIA POR 15 SEGUNDOS !!!        ${N}"
               echo -e "${A}────────────────────────────────────────────${N}"
               read -t 15 -p " Poner en linea despues de un reinicio [s/n]: " rc
               rc=${rc:-s}
               
               if [[ "$rc" == "s" || "$rc" == "S" ]]; then
                   echo -e "[Unit]\nDescription=BadVPN UDPGW\n[Service]\nExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10\nRestart=always\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/badvpn7300.service
                   echo -e "[Unit]\nDescription=BadVPN UDPGW Dual\n[Service]\nExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 10\nRestart=always\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/badvpn7200.service
                   systemctl daemon-reload
                   systemctl enable badvpn7300 >/dev/null 2>&1
                   systemctl enable badvpn7200 >/dev/null 2>&1
               fi
               
               systemctl start badvpn7300 2>/dev/null || nohup /usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 &
               systemctl start badvpn7200 2>/dev/null || nohup /usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 &
               
               read -p "Enter..." ;;
            2) 
               systemctl stop badvpn7300 2>/dev/null
               systemctl stop badvpn7200 2>/dev/null
               killall badvpn-udpgw 2>/dev/null
               echo -e "${A}BadVPN Detenido.${N}"; read -p "Enter..." ;;
            3) 
               systemctl stop badvpn7300 2>/dev/null
               systemctl stop badvpn7200 2>/dev/null
               systemctl disable badvpn7300 2>/dev/null
               systemctl disable badvpn7200 2>/dev/null
               rm -f /etc/systemd/system/badvpn*.service
               rm -f /usr/bin/badvpn-udpgw
               systemctl daemon-reload
               killall badvpn-udpgw 2>/dev/null
               echo -e "${R}BadVPN Desinstalado.${N}"; read -p "Enter..." ;;
            0) break ;;
        esac
    done
}

menu_protocolos() {
    while true; do
        clear
        P22=$(ep 22); P80=$(es proxypy); PSSL=$(es stunnel4); PPY=$(es proxypy); PUDP=$(es udp-custom); PFB=$(es fail2ban)
        PBAD=$(ss -ulnp | grep -q ":7300 " && echo -e "${V}[ON]${N}" || echo -e "${R}[OFF]${N}")
        
        echo -e "${A}🍄 INSTALACION DE PROTOCOLOS ( Script Osmaca ) 🍄${N}"
        echo -e "--------------------------------------------------------"
        echo -e " ${C}[1]${N} OpenSSH       $P22    ${C}[11]${N} PSIPHON SERVER ${R}[OFF]${N}"
        echo -e " ${C}[2]${N} DROPBEAR      ${R}[OFF]${N}    ${C}[12]${N} TCP DNS        ${A}(#BETA)${N}"
        echo -e " ${C}[3]${N} OPENVPN       ${R}[OFF]${N}    ${C}[13]${N} WEBMIN         ${R}[OFF]${N}"
        echo -e " ${C}[4]${N} SSL/TLS       $PSSL    ${C}[14]${N} SLOWDNS        ${R}[OFF]${N}"
        echo -e " ${C}[5]${N} SHADOWSOCKS-R ${R}[OFF]${N}    ${C}[15]${N} SSL->PYTHON    ${R}[OFF]${N}"
        echo -e " ${C}[6]${N} SQUID         ${R}[OFF]${N}    ${C}[16]${N} SSLH MULTIPLEX ${R}[OFF]${N}"
        echo -e " ${C}[7]${N} PROXY PYTHON  $PPY    ${C}[17]${N} OVER WEBSOCKET ${A}(#BETA)${N}"
        echo -e " ${C}[8]${N} V2RAY MANAGER ${R}[OFF]${N}    ${C}[18]${N} SOCKS5         ${A}(#BETA)${N}"
        echo -e " ${C}[9]${N} CFA ( CLASH ) ${R}[OFF]${N}    ${C}[19]${N} Protocolos UDP $PUDP"
        echo -e " ${C}[10]${N} TROJAN-GO     ${R}[OFF]${N}    ${C}[20]${N} ${C}FUNCIONES EN DISEÑO!${N}"
        echo -e " "
        echo -e "${A}🍄 INSTALACION DE HERRAMIENTAS Y SERVICIOS 🍄${N}"
        echo -e "-----------------------------------------------
