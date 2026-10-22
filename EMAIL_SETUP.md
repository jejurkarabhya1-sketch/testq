# Gmail SMTP setup (Android)

1. Open Google Account security and enable 2-Step Verification.
2. Create a dedicated 16-character Google App Password at https://myaccount.google.com/apppasswords.
3. In the app, open Settings → Email / SMTP Settings.
4. Enter the Gmail address used as **From**, the recipient address as **To**, and the App Password. Do not enter your normal Google account password.
5. Save, then open Reports → Email salary Excel. The app builds the selected month's workbook and attaches it to the email over Gmail SMTP with STARTTLS on port 587.

The Gmail App Password is stored using Android secure storage; sender and recipient addresses are stored in app preferences. SMTP sending requires internet access. A success message means the SMTP server accepted the message, not that the recipient has opened it or that it avoided spam filtering.

If it fails:
- `535` / authentication: create a new App Password, remove spaces, and save it again.
- connection timeout / socket error: check internet access, VPN/firewall, and try another network.
- recipient refused: verify the To address.
