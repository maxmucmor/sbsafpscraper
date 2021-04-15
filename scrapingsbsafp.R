# author: Max Mucha Morales
# date: Abril, 2021

# Antes de nada, limpiamos el workspace, por si hubiera alg?n dataset o informaci?n cargada
rm(list = ls())

# Cambiar el directorio de trabajo
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

# Cargamos las librerías que vamos a necesitar
# install.packages("wdman")
library(rvest)
library(RSelenium)
library(wdman)

# URL a la que queremos navegar
url<-"https://www.sbs.gob.pe/app/stats_net/stats/EstadisticaBoletinEstadistico.aspx?p=54#"

# Arrancamos una sesión web, "headless" (por línea de comando, sin interfaz gráfica)
#  (1) Crear el navegador
server <- phantomjs(port=5011L) # Quizás aquí nos dé un error: ya habremos fijado el puerto entonces
# (2) Abrir el navegador
browser <- remoteDriver(browserName = "phantomjs", port=5011L)
browser$open()
# (3) Navegue a la página web que hemos fijado previamente
browser$navigate(url)
# Podemos ver la apariencia visual de la web tomando capturas de pantalla. 
#   Esto será muy útil si empezamos a jugar con el formulario web
# (4) ¿Qué está viendo nuestro bot?
browser$screenshot(display=TRUE)

# (1) Scraping dinámico para que aparezcan los enlaces de las hojas excel
boton1 <- browser$findElement(using = 'xpath',
                                    value='//*[@id="Bot_00"]')
boton1$clickElement()
# Volvemos a ver qué tal va nuestra pantalla
browser$screenshot(display=TRUE)

# Ya se me ha desplegado el segundo botón: veo que contiene una URL que tiene un enlace para desplegar los excel
# Es mejor hacer scraping estático porque los nombres de los botones son iguales para ambos botones
# (2) Scraping estático sobre la web actual, dado que despliega ya la URL donde están los excels
pagina_actual<-browser$getPageSource()
enlaces <- read_html(pagina_actual[[1]]) %>% 
  html_nodes("a")%>% 
  html_attr("href")
enlaces # 2 enlaces, el primero es vacío, dado que solo pinta un botón, pero el segundo sí contiene lo que necesito
enlacefinal<-paste0("https://www.sbs.gob.pe/app/stats_net/stats/",enlaces[2])

# (3) Descargamos los enlaces que contengan los exceles de manera estática
enlacesExcel<-enlacefinal%>%
  read_html()%>%
  html_nodes(".LHDesple_CONTE_modulo")%>%
  html_nodes("a")%>%
  html_attr("href")
enlacesExcel

# (4) Descargamos todos los excel
for (i in 1:length(enlacesExcel)){
  # Me quedo con el nombre del archivo para su guardado
  nombreArchivo=paste0("output/excel/",strsplit(enlacesExcel[i],"/")[[1]][8])
  download.file(enlacesExcel[i], nombreArchivo, mode = "wb")
}

#################################################################################
#################################################################################
# No olvivemos nunca cerrar la sesión que hemos abierto. Sino, se dejará abierta.
#   (1) He cerrado el navegador
browser$close() 
#   (2) He parado el servidor
server$stop()
