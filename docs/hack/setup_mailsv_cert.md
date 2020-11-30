# How to setup mailsv certification

by yn

**This configuration is important to run the service**

## Summary

* After terraform, addtional manual installation steps are needed.
* Mailsv connections from mailer client are 143:IMAP STARTTLS, 587:SMTP STARTTLS.
* For them, we have to setup certbot(Let's encrypt) in mailsv host OS.
* apt install certbot had been done already.
* Follow instructions below.

Example domain in this document) mail.domain.com

## Setup certbot(Let's encrypt)

At first, open cloudflare, remember mailsv.[gcp|hc].domain.com 's IP,
and set it to mail.domain.com A record. (CNAME way is not allowed).

And of course, you have to add the MX record of the domain, set
it points to mail.domain.com.

```
sudo certbot certonly --manual
```

A sample steps:

```
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Enter email address (used for urgent renewal and security notices) (Enter 'c' to
cancel): your@mailaddress.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf. You must
agree in order to register with the ACME server at
https://acme-v02.api.letsencrypt.org/directory
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(A)gree/(C)ancel: A

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing to share your email address with the Electronic Frontier
Foundation, a founding partner of the Let's Encrypt project and the non-profit
organization that develops Certbot? We'd like to send you email about our work
encrypting the web, EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: N
Please enter in your domain name(s) (comma and/or space separated)  (Enter 'c'
to cancel): mail.domain.com
Obtaining a new certificate
Performing the following challenges:
http-01 challenge for mail.domain.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
NOTE: The IP of this machine will be publicly logged as having requested this
certificate. If you're running certbot in manual mode on a machine that is not
your server, please ensure you're okay with that.

Are you OK with your IP being logged?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Create a file containing just this data:

7jFstAudmqadMytyTYoZC_4FvRDlHKAJosLJrWWxxyM._dBIlZH8Cq_Isk-KuYvh-x6CW7nKGvh72GEmYK-wALI

And make it available on your web server at this URL:

http://mail.domain.com/.well-known/acme-challenge/7jFstAudmqadMytyTYoZC_4FvRDlHKAJosLJrWWxxyM

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/mail.domain.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/mail.domain.com/privkey.pem
   Your cert will expire on 2020-07-04. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

You have to setup the indicated challenge value to an url http://mail.domain.com/-.
You can setup the challenge url by using nginx docker.

```
bundle exec rake service:nginx
```

Place the challenge as an url in ~/docker_volumes/nginx_data/

After success,

```
sudo chmod 755 /etc/letsencrypt/live
```

Now it is OK. Restart docker and test or something


### Update certbot automatically

https://qiita.com/Kanno-san/items/1ceac30120ab5dfe523a

Update will be postponed actually until 30 days before the expiring day.

Check `/var/log/letsencrypt/letsencrypt.log`

```
sudo crontab -e
# twice a day 0:14, 12:14
14 0,12 * * * certbot renew
```

## Setup DKIM

```
source ~/opendax/bin/setup_mailsv.sh config dkim
```


You'll get a file.

NOTE) Replace domain.com with your domain:

```
sudo cat ~/opendax/config/mailsv/opendkim/keys/domain.com/mail.txt
```

So, you got a file, the content is like (dummy):

```
mail._domainkey IN      TXT     ( "v=DKIM1; h=sha256; k=rsa; "
          "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAfdsafdasfdsafdasqW2iolAu++mhdZBsM6mNj4w+vHzKXfLOgxXhXtg+EBRj/a5X8iA6NGY2RliHLV71pKu00z6qAn2ZpC7C6Vhfu3PnjNLqj2v2TBPTIjJFAtRPn63Og85S57gowYiObqqHXsnIB0/V77UBVp02z3hMW22lFnixyiRwIglpTROVX9nUs7duthDC3W46t5f4QRASC+FIHFc1PK"
          "CLcckXYRCZ72//cbOd9zAcf1WApMn5uKe3w3BiqeB3sHnxypIOOEMl9SuVkbjntGYcafZtML8QhvcBDyPANMB/R8q8FLS+DA7GoYcBxf/aXvndy4IJz+9pRPCHiwdC97D2k7AB6QIDAQAB" )  ; ----- DKIM key mail for domain.com
```

You put this into dns like this (format by yourself):

```
txt mail._domainkey v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIfdafdas4nqua43RaslX3MgwDyJ564Ss/GNWiZl0jFrXrESm7ifpOUsfjDAjzF4/m9Y6SFr/wSWkt6RnYPP02Tu7Xa1WrAvJh1LPYs6e5pOKYTxCAZXdS+ymaFyIBf2ipJ6ZNQwizZfJ3GmrvZJK4jXhfdafdaujmwl17j4ykj/3cm/OjzoXMmLktzj+gCBhqTH4MbaLc/jtjqdZ9eJYcQn8Ji7R9oF1HhlqCZ7OhyVqA+dUc5XyDskeHFJj3580Ww7lJF3aq9XzmPg6EfB0K+hHZ6C0+uverQpjwTcxnIvG530rNPdnT+XhDTgQb/+7fNZgkWpv3wIDAQAB
```


Check by this (set selector mail):

https://dmarcian.com/dkim-inspector/

**Notice) The record must be valid by this check site.**

## Setup SPF

It seems the below site's recommendation is OK.

https://diag.interlink.or.jp/spf

Like:

```
txt domain.com
v=spf1 +ip4:138.21.122.37/32 ~all
```

Check by this:

https://dmarcian.com/spf-survey/

**Notice) The record must be valid by this check site.**

EOF