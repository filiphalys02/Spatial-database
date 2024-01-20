import requests

url = 'http://localhost/fmedatadownload/Dashboards/ex_9.fmw?email=filiphalys02%40gmail.com&apikey=cc0a86b5-b0cb-463d-9d1e-931e93956d6a&datap=20230703000000&emailklient=filiphalys02%40gmail.com&datak=20230720000000&pokrycie=40&powiat=rzeszowski&SourceDataset_SHAPEFILE=C%3A%5CBazy-danych-przestrzennych%5CEx_9_FME%5Cpowiaty.shp&DestDataset_GEOTIFF=C%3A%5CBazy-danych-przestrzennych%5CEx_9_FME&opt_showresult=false&opt_servicemode=sync'
header = {'Authorization' : 'fmetoken token=3b7259685b80592987e5c11f97456f50b94d254f'}

x = requests.post(url, headers=header)

print(x.text)