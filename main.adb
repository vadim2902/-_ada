with Ada.Text_IO;
use Ada.Text_IO;

procedure Main is
   N : Integer := 12;
   type Stop_Durations is
     array (1 .. N) of Duration;

   type My_Boolean_Array is
     array (1 .. N) of Boolean;
   Can_Stop : My_Boolean_Array := (others => False);
   pragma Volatile(Can_Stop);

   task type Breaker is
      entry Start(Timers : Stop_Durations);
   end Breaker;

   task body Breaker is
      Timers : Stop_Durations;
      Min : Duration;
      MinElemIndex : Integer;
   begin
      accept Start (Timers : Stop_Durations) do
         Breaker.Timers := Timers;
      end Start;

      for I in Timers'Range loop
         -- Set not zero element
         for J in Timers'Range loop
            if Timers (J) /= 0.0 then
               Min := Timers (J);
               MinElemIndex := J;
            end if;
         end loop;

         -- Find Min element
         for J in Timers'Range loop
            if Timers (J) /= 0.0
              and then Min > Timers (J) then
               Min := Timers (J);
               MinElemIndex := J;
            end if;
         end loop;

         for J in Timers'Range loop
            if Timers (J) > Duration(0) then
               Timers (J) := Timers (J) - Min;
            end if;
         end loop;

         delay Min;
         Can_Stop (MinElemIndex) := true;
      end loop;
   end Breaker;

   task type MyThread is
      entry Start(Id : in Integer);
      entry Finish(Sum : out Long_Long_Integer);
   end MyThread;

   task body MyThread is
      Sum : Long_Long_Integer := 0;
      Id : Integer;
      I : Integer := 1;
   begin
      accept Start (Id : in Integer) do
         MyThread.Id := Id;
      end Start;

      loop
         Sum := Sum + 2;
         exit when Can_Stop(Id);
      end loop;
      Put_Line (Id'Img & " - " & Sum'Img);

      accept Finish (Sum : out Long_Long_Integer) do
         Sum := MyThread.Sum;
      end Finish;
   end MyThread;

   BreakThread : Breaker;
   Tasks : array (1 .. N) of MyThread;
   Sums : array (1 .. N) of Long_Long_Integer;
   Stop_Dur : Stop_Durations := (5.0, 4.0, 11.0, 12.0, 1.0, 2.0, 3.0, 6.0, 7.0, 8.0, 9.0, 10.0);
   --Stop_Dur : Stop_Durations := ( 1.0, 2.0, 3.0);

begin
   BreakThread.Start(Stop_Dur);

   for I in 1 .. N loop
      Tasks(I).Start(I);
   end loop;

   for I in 1 .. N loop
      Tasks(I).Finish(Sums(I));
   end loop;

end Main;
