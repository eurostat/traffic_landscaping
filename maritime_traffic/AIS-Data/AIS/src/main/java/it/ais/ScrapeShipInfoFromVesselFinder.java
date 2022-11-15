package it.ais;

import com.gargoylesoftware.htmlunit.FailingHttpStatusCodeException;
import com.gargoylesoftware.htmlunit.ProxyConfig;
import com.gargoylesoftware.htmlunit.WebClient;
import com.gargoylesoftware.htmlunit.WebClientOptions;
import com.gargoylesoftware.htmlunit.html.HtmlAnchor;
import com.gargoylesoftware.htmlunit.html.HtmlHeading2;
import com.gargoylesoftware.htmlunit.html.HtmlPage;
import com.gargoylesoftware.htmlunit.html.HtmlSection;
import com.gargoylesoftware.htmlunit.html.HtmlTable;
import com.gargoylesoftware.htmlunit.html.HtmlTableBody;
import com.gargoylesoftware.htmlunit.html.HtmlTableCell;
import com.gargoylesoftware.htmlunit.html.HtmlTableRow;
import it.ais.bean.ShipDetails;
import it.ais.db.InsertScrapeInfoIToDatabase;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class ScrapeShipInfoFromVesselFinder
{

   private static final boolean USE_PROXY = true;

   @SuppressWarnings("ConvertToTryWithResources")
   public static void main(String[] args)
   {
      try
      {
         Logger.getLogger(ScrapeShipInfoFromVesselFinder.class.getName()).log(Level.INFO, "Start ScrapeShipInfoFromVesselFinder");

         WebClient client = new WebClient();

         WebClientOptions options = client.getOptions();
         options.setCssEnabled(false);
         options.setJavaScriptEnabled(false);

         if (USE_PROXY)
         {
            String proxyHost = "*******";
            int proxyPort = 1234;
            ProxyConfig proxy = new ProxyConfig(proxyHost, proxyPort, null);
            options.setProxyConfig(proxy);
         }

         //get ship without info
         InsertScrapeInfoIToDatabase db = new InsertScrapeInfoIToDatabase();

         ArrayList<String> mmsis = db.selectDistinctShips();
         Logger.getLogger(ScrapeShipInfoFromVesselFinder.class.getName()).log(Level.INFO, "Ships to scrape {0}", mmsis.size());
         int rowsScraped = 0; 
         for (String mmsi : mmsis)
         {
            //scrape ship info from VesselFinder
            ShipDetails details = findShipDetails(client, mmsi);
             
            if (details != null)
            {
               details.setMmsi(mmsi);

               //insert ship info
               db.insertShipDetails(details);
               rowsScraped++; 
            }
         }
         Logger.getLogger(ScrapeShipInfoFromVesselFinder.class.getName()).log(Level.INFO, "Ships scraped {0}", rowsScraped);

         client.close();

         Logger.getLogger(ScrapeShipInfoFromVesselFinder.class.getName()).log(Level.INFO, "End ScrapeShipInfoFromVesselFinder");
      }
      catch (FailingHttpStatusCodeException | IOException ex)
      {
         Logger.getLogger(ScrapeShipInfoFromVesselFinder.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   public static ShipDetails findShipDetails(WebClient client, String mmsi) throws IOException
   {
      ShipDetails details = null;

      HtmlPage page = client.getPage("https://www.vesselfinder.com/vessels?name=" + mmsi);

      HtmlSection section = page.getFirstByXPath(".//section[@class='listing']");

      HtmlTableBody tableBody = section.getFirstByXPath(".//tbody");

      List<HtmlTableRow> rows = tableBody.getRows();
      if (!rows.isEmpty())
      {
         HtmlTableRow row = rows.get(0);//first row
         List<HtmlTableCell> cells = row.getCells();
         if (!cells.isEmpty())
         {
            //anchor
            HtmlTableCell cell = cells.get(0);
            String tmp = cell.asXml();
            HtmlAnchor anchor = cell.getFirstByXPath(".//a[@class='arc']");
            String url = anchor.getHrefAttribute();
            details = getShipDetails(client, url);
         }
      }

      return details;
   }

   public static ShipDetails getShipDetails(WebClient client, String url) throws IOException
   {
      ShipDetails details = null;

      HtmlPage page = client.getPage("https://www.vesselfinder.com/" + url);

      List<HtmlSection> sections = page.getByXPath("//section[@class='column ship-section']");
      if (!sections.isEmpty())
      {
         for (HtmlSection section : sections)
         {
            HtmlHeading2 h2 = section.getFirstByXPath(".//h2[@class='bar']");
            String text = h2.asNormalizedText();
            if (text.equals("Vessel Particulars"))
            {
               HtmlTable table = section.getFirstByXPath(".//table");
               List<HtmlTableRow> rows = table.getRows();
               int rowSelected = 0;
               details = new ShipDetails();
               for (HtmlTableRow row : rows)
               {
                  rowSelected++;
                  List<HtmlTableCell> cells = row.getCells();
                  if (!cells.isEmpty())
                  {
                     //anchor
                     HtmlTableCell cellHeader = cells.get(0);
                     String header = cellHeader.asNormalizedText();
                     HtmlTableCell cellValue = cells.get(1);
                     String value = cellValue.asNormalizedText();

                     switch (header)
                     {
                        case "IMO number":
                           details.setImo(value);
                           break;
                        case "Vessel Name":
                           details.setName(value);
                           break;
                        case "Ship type":
                           details.setType(value);
                           break;
                        case "Flag":
                           details.setFlag(value);
                           break;
                        case "Gross Tonnage":
                           details.setGrossTonnage(value);
                           break;
                        case "Summer Deadweight (t)":
                           details.setDeadweight(value);
                           break;
                        case "Length Overall (m)":
                           details.setLength(value);
                           break;
                        case "Beam (m)":
                           details.setWidth(value);
                           break;
                        case "Year of Built":
                           details.setYear(value);
                           break;
                     }
                  }
               }
            }
         }
      }

      return details;
   }

}
