# jupyter-azure-ad
Run Jupyter notebooks on Azure VMs with Active Directory integration


Create an **.env** file:

```
cat << EOF > .env
subscriptionId=<your azure subscription id>
spotInstance=true
vmAdminPassword=<someRandomStrin>
# vmSize=Standard_NC24_Promo
vmSize=Standard_NC24
tenantId=<your azure tenantId>
EOF
```

afterwards you are all set. Just run the make create command to spin everything up


```
make create
```

if you want to cleanup all resources, run:


```
make cleanup
```
