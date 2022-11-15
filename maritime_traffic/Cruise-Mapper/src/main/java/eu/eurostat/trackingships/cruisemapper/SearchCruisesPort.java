package eu.eurostat.trackingships.cruisemapper;

import eu.eurostat.trackingships.utility.KillHangDriverProcess;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.apache.commons.lang3.BooleanUtils;
import org.openqa.selenium.By;
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

public class SearchCruisesPort
{

   private static final Logger LOGGER = Logger.getLogger(SearchCruisesPort.class.getName());

   private static final String FILE_COLS_SEP = ";";

   public static void main(String[] args) throws InterruptedException
   {
      try
      {
         //read properties files for directory path
         InputStream propsFile = SearchCruisesPort.class.getClassLoader().getResourceAsStream("config.properties");
         Properties props = new Properties();
         props.load(propsFile);
         String dirRoot = props.getProperty("root_directory");
         String subDir = props.getProperty("subdir_cruisemapper");
         String subDirCruisesFleet = props.getProperty("subdir_cruisemapper_cruisesfleet");
         String fileInName = props.getProperty("file_cruisemapper_port");
         String fileOutName = props.getProperty("file_cruisemapper_port_geo");

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

         //read file input
         File fileIn = new File(dirNamePortVoyageInfo + File.separator + fileInName);
         FileInputStream fis = new FileInputStream(fileIn);
         InputStreamReader ir = new InputStreamReader(fis, StandardCharsets.UTF_8.name());
         BufferedReader br = new BufferedReader(ir);

         //write file output itinerary
         File fileOut = new File(dirNamePortVoyageInfo + File.separator + fileOutName);
         FileOutputStream fos = new FileOutputStream(fileOut);
         OutputStreamWriter ow = new OutputStreamWriter(fos, StandardCharsets.UTF_8.name());
         BufferedWriter bw = new BufferedWriter(ow);
         
         //init web driver
         String logPort = dirNamePortVoyageInfo + File.separator + "Port.log";
         WebDriver driverPort = intiWebClient(logPort);

         //cycle read input file
         while (true)
         {
            //get line
            String line = br.readLine();
         
            //exit
            if (line == null)
            {
               break;
            }              

            //split string
            String cols[] = line.split(FILE_COLS_SEP);     
            String urlPort = cols[1];
            LOGGER.log(Level.INFO, "url port: {0}", urlPort);

            //get port
            getPort(bw, line, urlPort, driverPort);
         }//while 

         //close web driver
         driverPort.close();

         //close file input
         br.close();
         ir.close();
         fis.close();

         //close file output
         bw.close();
         ow.close();
         fos.close();
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
   private static void getPort(BufferedWriter bw, String line, String urlPort, WebDriver driverPort) 
           throws IOException, InterruptedException
   {
      try
      {
         //get url 
         driverPort.get(urlPort);

         //wait 2 seconds
         Thread.sleep(2 * 1000);
         
         //get element
         WebElement anchor = driverPort.findElement(By.xpath(".//a[@class='btnGreen portButton portIzosa']"));
         String urlPortMap = anchor.getAttribute("href");
         LOGGER.log(Level.INFO, "url port map: {0}", urlPortMap);

         //get Port map
         getPortMap(bw, line, urlPortMap, driverPort);
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
         //restart get port
         getPort(bw, line, urlPort, driverPort);
      }
   }

   @SuppressWarnings("InfiniteRecursion")
   private static void getPortMap(BufferedWriter bw, String line, String urlPortMap, WebDriver driverPort) 
           throws IOException, InterruptedException
   {
      try
      {
         //get url 
         driverPort.get(urlPortMap);

         //wait 2 seconds
         Thread.sleep(2 * 1000);
         
         //get element lat/lon
         WebElement listItem1 = driverPort.findElement(By.xpath(".//li[@id='trackerItemSpec_1']"));
         //get element 
         WebElement spanLatLon = listItem1.findElement(By.xpath(".//span[@class='specValue']")); 
         //extact lat/lon
         String latLon = spanLatLon.getText();
         String lat = "";
         String lon = "";
         if (!latLon.isEmpty())
         {
            int start = 0;
            int end = latLon.indexOf(", ");
            lat = latLon.substring(start, end);
            start = end + (", ").length();
            end = latLon.length();
            lon = latLon.substring(start, end);
            LOGGER.log(Level.INFO, "lat: {0}, lon: {1}", new Object[]{lat, lon});
         }
         //get element port code
         WebElement listItem2 = driverPort.findElement(By.xpath(".//li[@id='trackerItemSpec_2']"));
         //get element 
         WebElement spanPortCode = listItem2.findElement(By.xpath(".//span[@class='specValue']")); 
         //extact port code
         String portCode = spanPortCode.getText();
         LOGGER.log(Level.INFO, "port code: {0}", portCode);

         //write line
         line += FILE_COLS_SEP + lat + FILE_COLS_SEP + lon + FILE_COLS_SEP + portCode;
         bw.write(line);
         bw.newLine();     
         bw.flush();     
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
         //restart get port map
         getPortMap(bw, line, urlPortMap, driverPort);
      }
   }

   private static WebDriver intiWebClient(String logFileName) throws IOException
   {
      WebDriver driver;

      //read properties files for web driver
      InputStream propsFile = SearchCruisesPort.class.getClassLoader().getResourceAsStream("driver.properties");
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
      propsFile = SearchCruisesPort.class.getClassLoader().getResourceAsStream("proxy.properties");
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
