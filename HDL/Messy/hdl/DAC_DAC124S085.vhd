--
-- VHDL Architecture Poetic.DAC.DAC124S085
--
-- Created:
--          by - jeann.UNKNOWN (DESKTOP-V46KISN)
--          at - 09:21:02 18.06.2021
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--
ARCHITECTURE DAC124S085 OF DAC IS
  constant numberOfDataToSend : integer := 12;
  signal memSCLK, risingSCLK : std_ulogic;
  signal masterWr : std_ulogic;
  signal masterData : std_ulogic_vector(dacBitNb+dacChBitNb+dacOpBitNb-1 DOWNTO 0);
  type transmitState is(
    waitForATransmission, sendData, sendLowSync, sendHighSync, sendZero
  );
  signal mainState : transmitState;
BEGIN
  concatenate : process (reset, clock)
  begin
    if reset = '1' then
      masterData <= (others => '0');
      masterWr <= '0';
    elsif rising_edge(clock) then
    masterWr <= '0';
      if send = '1' then
        masterData <= dacSel & mode & data;
        masterWr <= '1';
      end if;
    end if;
  end process concatenate;
  
  transmit : process (reset, clock)
  variable decounter : integer;
  variable counter : integer;
  begin
    if reset = '1' then
      mainState <= waitForATransmission;
      decounter := masterData'length-1;
      Sync_n <= '1';
      Dout <= '0';
	  counter := 0;
    elsif rising_edge(clock) then
      case mainState is
        when waitForATransmission =>
          if masterWr = '1' then
            mainState <= sendLowSync;
          end if;
        when sendData =>
          if risingSCLK = '1' then
            decounter := decounter - 1;
            Dout <= masterData(decounter);
            if decounter = 0 then
              mainState <= sendZero;
            end if;
          end if;
        when sendLowSync =>
          if risingSCLK = '1' then
            Sync_n <= '0';
            Dout <= masterData(decounter);
            mainState <= sendData;
          end if;
        when sendHighSync =>
          decounter := masterData'length-1;
          counter := 0;
          if risingSCLK = '1' then
            Sync_n <= '1';
            mainState <= waitForATransmission;
          end if;
		when sendZero =>
		  if risingSCLK = '1' then
		    Dout <= '0';
			counter := counter + 1;
      end if;
			if counter >= numberOfDataToSend - dacBitNb then
			  mainState <= sendHighSync;
		  end if;
      end case;
    end if;
  end process transmit;
  
  detectRisingSCLK : process (reset, clock)
  begin
    if reset = '1' then
      memSCLK <= '0';
      risingSCLK <= '0';
    elsif rising_edge(clock) then
      risingSCLK <= '0';
      if memSCLK = '0' AND SCLK = '1' then
        risingSCLK <= '1';
        memSCLK <= SCLK;
      else
        memSCLK <= SCLK;
      end if;
    end if;
  end process detectRisingSCLK;
END ARCHITECTURE DAC124S085;

