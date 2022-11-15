package eu.eurostat.trackingships.cruisemapper;

import eu.eurostat.trackingships.utility.KillHangDriverProcess;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.apache.commons.lang3.BooleanUtils;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.openqa.selenium.remote.CapabilityType;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.Proxy;
import org.openqa.selenium.SessionNotCreatedException;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.logging.LogType;
import org.openqa.selenium.logging.LoggingPreferences;

public class SearchCruisesFleet
{

   private static final Logger LOGGER = Logger.getLogger(SearchCruisesFleet.class.getName());

   private static final String FILE_COLS_SEP = ";";

   public static void main(String[] args) throws InterruptedException
   {
      try
      {
         //read properties files for directory path
         InputStream propsFile = SearchCruisesFleet.class.getClassLoader().getResourceAsStream("config.properties");
         Properties props = new Properties();
         props.load(propsFile);
         String dirRoot = props.getProperty("root_directory");
         String subDir = props.getProperty("subdir_cruisemapper");
         String subDirCruisesFleet = props.getProperty("subdir_cruisemapper_cruisesfleet");
         String fileName = props.getProperty("file_index_cruisemapper_cruisesfleet");
         String fileNameIt = props.getProperty("file_itinerary_cruisemapper_cruisesfleet");
         String fileNameIts = props.getProperty("file_itineraries_cruisemapper_cruisesfleet");

         //create directory Cruise Mapper
         String dirName = dirRoot + File.separator + subDir;
         File directory = new File(dirName);
         if (!directory.exists())
         {
            directory.mkdir();
         }
         //create directory Cruises Fleet
         String dirNamePortVoyageInfo = dirName + File.separator + subDirCruisesFleet;
         directory = new File(dirNamePortVoyageInfo);
         if (!directory.exists())
         {
            directory.mkdir();
         }

         //get date time 
         DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy_MM_dd");
         LocalDateTime now = LocalDateTime.now();
         String nowFormatted = dtf.format(now);

         //write file output
         File fileOut = new File(dirNamePortVoyageInfo + File.separator + nowFormatted + "_" + fileName);
         FileOutputStream fs = new FileOutputStream(fileOut);
         OutputStreamWriter ow = new OutputStreamWriter(fs, StandardCharsets.UTF_8.name());
         BufferedWriter bw = new BufferedWriter(ow);

         //write file output itinerary
         File fileOutIt = new File(dirNamePortVoyageInfo + File.separator + nowFormatted + "_" + fileNameIt);
         FileOutputStream fsIt = new FileOutputStream(fileOutIt);
         OutputStreamWriter owIt = new OutputStreamWriter(fsIt, StandardCharsets.UTF_8.name());
         BufferedWriter bwIt = new BufferedWriter(owIt);

         //write file output itineraries
         File fileOutIts = new File(dirNamePortVoyageInfo + File.separator + nowFormatted + "_" + fileNameIts);
         FileOutputStream fsIts = new FileOutputStream(fileOutIts);
         OutputStreamWriter owIts = new OutputStreamWriter(fsIts, StandardCharsets.UTF_8.name());
         BufferedWriter bwIts = new BufferedWriter(owIts);

         //write file output header
         String header = "urlShips" + FILE_COLS_SEP + "urlShip" + FILE_COLS_SEP + "currPosText" + FILE_COLS_SEP + "lat" + FILE_COLS_SEP + 
                         "lon" + FILE_COLS_SEP + "passengers" + FILE_COLS_SEP + "crew" + FILE_COLS_SEP + "cabins";
         bw.write(header);
         bw.newLine();                   

         //write file output itinerary
         String headerIt = "urlShips" + FILE_COLS_SEP + "urlShip" + FILE_COLS_SEP + "currItText" + FILE_COLS_SEP + "currItDate" + FILE_COLS_SEP + "currItPort" + FILE_COLS_SEP + "urlPort";
         bwIt.write(headerIt);
         bwIt.newLine();    
         
         //write file output itineraries
         String headerIts = "urlShips" + FILE_COLS_SEP + "urlShip" + FILE_COLS_SEP + "nextItText" + FILE_COLS_SEP + "nextItDate" + FILE_COLS_SEP + "nextItPort" + FILE_COLS_SEP + "urlPort";
         bwIts.write(headerIts);
         bwIts.newLine();            
         
         //init web driver
         String logShips = dirNamePortVoyageInfo + File.separator + "Ships.log";
         WebDriver driverShips = intiWebClient(logShips);
         String logShip = dirNamePortVoyageInfo + File.separator + "Ship.log";
         WebDriver driverShip = intiWebClient(logShip);

         //set url 
         final String urlShips = "https://www.cruisemapper.com/ships";
         LOGGER.log(Level.INFO, "url ships: {0}", urlShips);

         //get ships
         getShips(bw, bwIt, bwIts, urlShips, driverShips, driverShip);

         //close web driver
         driverShip.close();
         driverShips.close();

         //close file output itinerary
         bwIt.close();
         owIt.close();
         fsIt.close();
         
         //close file output
         bw.close();
         ow.close();
         fs.close();
      }
      catch (IOException ex)
      {
         LOGGER.log(Level.SEVERE, ex.getMessage());
      }
      catch (InterruptedException ex)
      {
         LOGGER.log(Level.SEVERE, ex.getMessage());
      }
      catch (Exception ex)
      {
         LOGGER.log(Level.SEVERE, ex.getMessage());
      }
      catch (Throwable ex)
      {
         LOGGER.log(Level.SEVERE, ex.getMessage());
      }      
      finally
      {
         KillHangDriverProcess killDriverProcess = new KillHangDriverProcess();
         killDriverProcess.start();
      }

   }

   @SuppressWarnings("InfiniteRecursion")
   private static void getShips(BufferedWriter bw, BufferedWriter bwIt, BufferedWriter bwIts, String urlShips, WebDriver driverShips, WebDriver driverShip) 
           throws IOException, InterruptedException
   {
      try
      {
         //get url 
         driverShips.get(urlShips);

         //wait 5 seconds
         Thread.sleep(5 * 1000);
         
         //get elements
         WebElement ul = driverShips.findElement(By.xpath(".//ul[@class='row shipList']"));
         List<WebElement> lis = ul.findElements(By.xpath(".//li"));

         //cylcle ships
         for (WebElement li : lis)
         {
            WebElement h3 = li.findElement(By.xpath(".//h3"));
            WebElement a = h3.findElement(By.xpath(".//a"));
            String nameShip = a.getText().trim();
            LOGGER.log(Level.INFO, "name ship: {0}", nameShip);
            String urlShip = a.getAttribute("href");
            LOGGER.log(Level.INFO, "url ship: {0}", urlShip);
            //get ship
            getShip(bw, bwIt, bwIts, urlShips, urlShip, driverShip);
         }

         //flush file output
         bw.flush();             
         
         //manage pagination
         WebElement ulPager = driverShips.findElement(By.xpath(".//ul[@class='pager']"));
         List<WebElement> lisPager = ulPager.findElements(By.xpath(".//li"));
         if (!lisPager.isEmpty())
         {
            int iLast = lisPager.size() - 1;
            WebElement liLast = lisPager.get(iLast);
            String classLast = liLast.getAttribute("class");
            if (classLast.startsWith("desktop"))
            {
               LOGGER.log(Level.INFO, "end of ship pagination");
            }
            else
            {
               WebElement aNext = liLast.findElement(By.xpath(".//a"));
               urlShips = aNext.getAttribute("href");
               LOGGER.log(Level.INFO, "url next ships: {0}", urlShips);
               //get next ships
               getShips(bw, bwIt, bwIts, urlShips, driverShips, driverShip);
            }
         }
      }
      catch (SessionNotCreatedException | TimeoutException ex)
      {
         try
         {
            LOGGER.log(Level.SEVERE, ex.getMessage());
            //wait 5 minute
            Thread.sleep(5 * 60 * 1000);//wait 5 minutes
         }
         catch (InterruptedException exNested)
         {
            LOGGER.log(Level.SEVERE, exNested.getMessage());
         }
         //restart get ships
         getShips(bw, bwIt, bwIts, urlShips, driverShips, driverShip);
      }
   }

   @SuppressWarnings("InfiniteRecursion")
   private static void getShip(BufferedWriter bw, BufferedWriter bwIt, BufferedWriter bwIts, String urlShips, String urlShip, WebDriver driverShip) 
           throws IOException, InterruptedException
   {
      try
      {
         //get url 
         driverShip.get(urlShip);
         
         //wait 5 seconds
         Thread.sleep(5 * 1000);

         //javascript executor
         JavascriptExecutor executor = (JavascriptExecutor) driverShip;
         
         //
         String line = "";
         String lineIt = "";
         String lineIts = "";

         //get ship current position
         String currPosText = "";
         String lat = "";
         String lon = "";
         try
         {
            List<WebElement> headersCurrPos = driverShip.findElements(By.xpath(".//h3[@id='current_cruise']"));
            for (WebElement headerCurrPos : headersCurrPos)
            {
               String headerText = headerCurrPos.getText().toLowerCase().trim();
               if (headerText.endsWith("current position"))
               {
                  WebElement parentCurrPos = headerCurrPos.findElement(By.xpath("./.."));
                  WebElement paragraphCurrPos = parentCurrPos.findElement(By.xpath(".//p"));
                  currPosText = paragraphCurrPos.getText().toLowerCase();
                  final String START_LAT_TEXT = "(coordinates ";
                  final String END_LAT_TEXT = " / ";
                  int start = currPosText.indexOf(START_LAT_TEXT) + START_LAT_TEXT.length();
                  int end = currPosText.indexOf(END_LAT_TEXT);
                  if (start != -1 && end != -1)
                  {
                     lat = currPosText.substring(start, end);
                     //clean 
                     lat = lat.replaceAll("[^0-9.-]", "");
                     final String END_LON_TEXT = ") ";
                     start = end + END_LAT_TEXT.length();
                     end = currPosText.indexOf(END_LON_TEXT);
                     if (start != -1 && end != -1)
                     {
                        lon = currPosText.substring(start, end);
                        //clean 
                        lon = lon.replaceAll("[^0-9.-]", "");
                     }
                  }
               }
            }
         }
         catch (NoSuchElementException ex)
         {
            LOGGER.log(Level.WARNING, "no data for current position!");
         }

         //get ship specifications
         String passengers = "";
         String crew = "";
         String cabins = "";
         try
         {
            WebElement tableSpec = driverShip.findElement(By.xpath(".//table[@class='table table-striped col-sm-6']"));
            List<WebElement> rows = tableSpec.findElements(By.xpath(".//tr"));
            //cycle rows
            for (int i=0; i<rows.size(); i++)
            {
               WebElement row = rows.get(i);
               List<WebElement> cells = row.findElements(By.xpath(".//td"));
               //get header and value
               WebElement cellHeader = cells.get(0);
               WebElement cellValue = cells.get(1);
               String header = cellHeader.getText().trim();
               switch (header)
               {
                  case "Passengers":
                     passengers = cellValue.getText().trim();
                     break;
                  case "Crew":
                     crew = cellValue.getText().trim();
                     break;
                  case "Cabins":
                     cabins = cellValue.getText().trim();
                     break;
               }
               //exit from for
               if (i >= 4)
               {
                  break;
               }               
            }
         }
         catch (NoSuchElementException ex)
         {
            LOGGER.log(Level.WARNING, "no data for specifications!");
         }
         
         //write file output  
         line = urlShips + FILE_COLS_SEP +
               urlShip + FILE_COLS_SEP +
               currPosText + FILE_COLS_SEP +
               lat + FILE_COLS_SEP +
               lon + FILE_COLS_SEP +
               passengers + FILE_COLS_SEP +
               crew + FILE_COLS_SEP +
               cabins + FILE_COLS_SEP;
         LOGGER.log(Level.INFO, "line: {0}", line);

         bw.write(line);
         bw.newLine();             
         
         //get ship current itinerary
         String currItText = "";
         String currItDate = "";
         String currItPort = "";
         
         //get date year
         DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy");
         LocalDateTime now = LocalDateTime.now();
         String yearFormatted = dtf.format(now);
         
         try
         {
            List<WebElement> headersCurrIt = driverShip.findElements(By.xpath(".//h3[@id='current_cruise']"));
            for (WebElement headerCurrIt : headersCurrIt)
            {
               String headerText = headerCurrIt.getText().toLowerCase().trim();
               if (headerText.startsWith("current itinerary"))
               {
                  WebElement parentCurrIt = headerCurrIt.findElement(By.xpath("./.."));
                  WebElement paragraphCurrIt = parentCurrIt.findElement(By.xpath(".//p"));
                  currItText = paragraphCurrIt.getText().trim();
                  //
                  WebElement tableCurrIt = parentCurrIt.findElement(By.xpath(".//table"));
                  List<WebElement> rows = tableCurrIt.findElements(By.xpath(".//tr"));
                  //cycle rows
                  for (int i=1; i<rows.size(); i++)
                  {
                     WebElement row = rows.get(i);
                     List<WebElement> cells = row.findElements(By.xpath(".//td"));   
                     WebElement cellDateValue = cells.get(0);
                     WebElement cellPortValue = cells.get(1);
                     currItDate = yearFormatted + " " + cellDateValue.getText().trim();
                     currItPort = cellPortValue.getText().trim();
                     currItPort = currItPort.replaceAll("hotels", "");
                     currItPort = currItPort.replaceAll("[\n\r]", "");
                     WebElement portAnchor = cellPortValue.findElement(By.xpath(".//a"));
                     String urlPort = portAnchor.getAttribute("href");

         
                     //write file output itinerary
                     lineIt = urlShips + FILE_COLS_SEP +
                              urlShip + FILE_COLS_SEP +
                              currItText + FILE_COLS_SEP +
                              currItDate + FILE_COLS_SEP +
                              currItPort + FILE_COLS_SEP + 
                              urlPort;
                     LOGGER.log(Level.INFO, "line itinerary: {0}", lineIt);

                     bwIt.write(lineIt);
                     bwIt.newLine();     
                  }
               }
            }
            //flush file output itinerary
            bwIt.flush();            
         }
         catch (NoSuchElementException ex)
         {
            LOGGER.log(Level.WARNING, "no data for current itinerary!");
         }
         
         //get ship next itineraries
         String nextItText = "";
         String nextItDate = "";
         String nextItPort = "";
         try
         {
            WebElement divNextIts = driverShip.findElement(By.xpath(".//div[@id='itinerary']"));
            WebElement tableNextIt = divNextIts.findElement(By.xpath(".//table"));
            List<WebElement> rows = tableNextIt.findElements(By.xpath(".//tr"));
            //cycle rows
            for (int i=1; i<rows.size(); i++)
            {
               WebElement row = rows.get(i);
               List<WebElement> cells = row.findElements(By.xpath(".//td"));
               WebElement cellDateValue = cells.get(0);
               nextItText = cellDateValue.getText();
               yearFormatted = nextItText.substring(0, 4);
               WebElement cellTextValue = cells.get(1);
               nextItText = cellTextValue.getText().trim();
               //click row
               executor.executeScript("arguments[0].click();", row);               
               WebElement trExpandIt = driverShip.findElement(By.xpath(".//tr[@class='cruiseExpandRow']"));
               WebElement tableExpandIt = trExpandIt.findElement(By.xpath(".//table"));
               List<WebElement> rowsExpand = tableExpandIt.findElements(By.xpath(".//tr"));
               //cycle rows
               for (int ii=1; ii<rowsExpand.size(); ii++)
               {
                  WebElement rowExpand = rowsExpand.get(ii);
                  List<WebElement> cellsExpand = rowExpand.findElements(By.xpath(".//td"));   
                  cellDateValue = cellsExpand.get(0);
                  WebElement cellPortValue = cellsExpand.get(1);
                  WebElement portAnchor = cellPortValue.findElement(By.xpath(".//a"));
                  String urlPort = portAnchor.getAttribute("href");
                  nextItDate = yearFormatted + " " + cellDateValue.getText().trim();
                  nextItPort = cellPortValue.getText().trim();
                  nextItPort = nextItPort.replaceAll("hotels", "");
                  nextItPort = nextItPort.replaceAll("[\n\r]", "");
                  
                  //write file output itinerary
                  lineIts = urlShips + FILE_COLS_SEP +
                            urlShip + FILE_COLS_SEP +
                            nextItText + FILE_COLS_SEP +
                            nextItDate + FILE_COLS_SEP +
                            nextItPort + FILE_COLS_SEP +
                            urlPort;
                  LOGGER.log(Level.INFO, "line itineraries: {0}", lineIts);               
               
                  bwIts.write(lineIts);
                  bwIts.newLine();     
               }               
               //click row
               executor.executeScript("arguments[0].click();", row);               
            }
            //flush file output itineraries
            bwIts.flush();            
         }
         catch (NoSuchElementException ex)
         {
            LOGGER.log(Level.WARNING, "no data for current itineraries!");
         }    
      }
      catch (SessionNotCreatedException | TimeoutException ex)
      {
         try
         {
            LOGGER.log(Level.SEVERE, ex.getMessage());
            //wait 5 minute
            Thread.sleep(5 * 60 * 1000);//wait 5 minutes
         }
         catch (InterruptedException exNested)
         {
            LOGGER.log(Level.SEVERE, exNested.getMessage());
         }
         //restart search
         getShip(bw, bwIt, bwIts, urlShips, urlShip, driverShip);
      }
      //wait 5 minute
      //wait 5 minutes
      //restart search

   }

   private static WebDriver intiWebClient(String logFileName) throws IOException
   {
      WebDriver driver;

      //read properties files for web driver
      InputStream propsFile = SearchCruisesFleet.class.getClassLoader().getResourceAsStream("driver.properties");
      Properties props = new Properties();
      props.load(propsFile);
      String driver_file = props.getProperty("web_driver_file");

      //setting gecko driver file
      System.setProperty("webdriver.gecko.driver", driver_file);
      //setting marionette
      System.setProperty("webdriver.firefox.marionette", "true");
      //setting log file
      System.setProperty(FirefoxDriver.SystemProperty.BROWSER_LOGFILE, logFileName);

      //set firefox Javascript error level logs
      LoggingPreferences logPrefs = new LoggingPreferences();
      logPrefs.enable(LogType.BROWSER, Level.SEVERE);
      FirefoxOptions firefoxOptions = new FirefoxOptions();
      firefoxOptions.setCapability(CapabilityType.LOGGING_PREFS, logPrefs);

      //read properties files for proxy
      propsFile = SearchCruisesFleet.class.getClassLoader().getResourceAsStream("proxy.properties");
      props = new Properties();
      props.load(propsFile);
      boolean enabled = BooleanUtils.toBoolean(props.getProperty("proxy_enabled"));
      if (enabled)
      {
         String host = props.getProperty("proxy_host");
         String port = props.getProperty("proxy_port");
         String hostAndPort = host + ":" + port;
         //setting firefox proxy
         Proxy proxy = new Proxy();
         proxy.setHttpProxy(hostAndPort);
         proxy.setSslProxy(hostAndPort);
         firefoxOptions.setCapability(CapabilityType.PROXY, proxy);
      }

      //open driver
      driver = new FirefoxDriver(firefoxOptions);

      //set driver options
      WebDriver.Options options = driver.manage();
      WebDriver.Timeouts timeouts = options.timeouts();
      timeouts.pageLoadTimeout(Duration.ofMinutes(1));
      timeouts.scriptTimeout(Duration.ofMinutes(1));
      timeouts.implicitlyWait(Duration.ofSeconds(10));

      //change window dimension
      WebDriver.Window window = options.window();
      window.maximize();

      return driver;
   }

}
