package it.ais.bean;

import com.opencsv.bean.CsvBindByName;

public class Ship
{

   @CsvBindByName(column = "MMSI")
   private String mmsi;

   @CsvBindByName(column = "TSTAMP")
   private String tstamp;

   @CsvBindByName(column = "LATITUDE")
   private String latitude;

   @CsvBindByName(column = "LONGITUDE")
   private String longitude;

   @CsvBindByName(column = "COG")
   private String cog;

   @CsvBindByName(column = "SOG")
   private String sog;

   @CsvBindByName(column = "HEADING")
   private String heading;

   @CsvBindByName(column = "NAVSTAT")
   private String navstat;

   @CsvBindByName(column = "IMO")
   private String imo;

   @CsvBindByName(column = "NAME")
   private String name;

   @CsvBindByName(column = "CALLSIGN")
   private String callsign;

   @CsvBindByName(column = "TYPE")
   private String type;

   @CsvBindByName(column = "A")
   private String a;

   @CsvBindByName(column = "B")
   private String b;

   @CsvBindByName(column = "C")
   private String c;

   @CsvBindByName(column = "D")
   private String d;

   @CsvBindByName(column = "DRAUGHT")
   private String daught;

   @CsvBindByName(column = "DEST")
   private String dest;

   @CsvBindByName(column = "ETA")
   private String eta;

   public String getMmsi()
   {
      return mmsi;
   }

   public void setMmsi(String mmsi)
   {
      this.mmsi = mmsi;
   }

   public String getTstamp()
   {
      return tstamp;
   }

   public void setTstamp(String tstamp)
   {
      this.tstamp = tstamp;
   }

   public String getLatitude()
   {
      return latitude;
   }

   public void setLatitude(String latitude)
   {
      this.latitude = latitude;
   }

   public String getLongitude()
   {
      return longitude;
   }

   public void setLongitude(String longitude)
   {
      this.longitude = longitude;
   }

   public String getCog()
   {
      return cog;
   }

   public void setCog(String cog)
   {
      this.cog = cog;
   }

   public String getSog()
   {
      return sog;
   }

   public void setSog(String sog)
   {
      this.sog = sog;
   }

   public String getHeading()
   {
      return heading;
   }

   public void setHeading(String heading)
   {
      this.heading = heading;
   }

   public String getNavstat()
   {
      return navstat;
   }

   public void setNavstat(String navstat)
   {
      this.navstat = navstat;
   }

   public String getImo()
   {
      return imo;
   }

   public void setImo(String imo)
   {
      this.imo = imo;
   }

   public String getName()
   {
      return name;
   }

   public void setName(String name)
   {
      this.name = name;
   }

   public String getCallsign()
   {
      return callsign;
   }

   public void setCallsign(String callsign)
   {
      this.callsign = callsign;
   }

   public String getType()
   {
      return type;
   }

   public void setType(String type)
   {
      this.type = type;
   }

   public String getA()
   {
      return a;
   }

   public void setA(String a)
   {
      this.a = a;
   }

   public String getB()
   {
      return b;
   }

   public void setB(String b)
   {
      this.b = b;
   }

   public String getC()
   {
      return c;
   }

   public void setC(String c)
   {
      this.c = c;
   }

   public String getD()
   {
      return d;
   }

   public void setD(String d)
   {
      this.d = d;
   }

   public String getDaught()
   {
      return daught;
   }

   public void setDaught(String daught)
   {
      this.daught = daught;
   }

   public String getDest()
   {
      return dest;
   }

   public void setDest(String dest)
   {
      this.dest = dest;
   }

   public String getEta()
   {
      return eta;
   }

   public void setEta(String eta)
   {
      this.eta = eta;
   }

   @Override
   public String toString()
   {
      return "Ship{" + "mmsi=" + mmsi + ", tstamp=" + tstamp + ", latitude=" + latitude + ", longitude=" + longitude + ", cog=" + cog + ", sog=" + sog + ", heading=" + heading + ", navstat=" + navstat + ", imo=" + imo + ", name=" + name + ", callsign=" + callsign + ", type=" + type + ", a=" + a + ", b=" + b + ", c=" + c + ", d=" + d + ", daught=" + daught + ", dest=" + dest + ", eta=" + eta + '}';
   }

}
