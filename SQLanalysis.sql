use [Road Accident]


-- أجمالي عدد الحوادث
SELECT COUNT(*) AS Total_Accidents
FROM Road_Acc


--متوسط الحوادث شهريا
SELECT AVG(Monthly_Count) AS Average_Monthly_Accidents
FROM (
    SELECT Month, COUNT(*) AS Monthly_Count
    FROM Road_Acc
    GROUP BY Month) AS Monthly_Data;


--تطور الحوادث شهريًا بمرور السنوات
SELECT YEAR(Accident_Date) AS Year,month(Accident_Date),COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY YEAR(Accident_Date), month(Accident_Date)
ORDER BY Year, month(Accident_Date);


-- توقع الشهر الأعلى في عدد الحوادث
SELECT top 1
Month , COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Month
ORDER BY Accident_Count DESC;


 -- معدل الحوادث في الويك اند مقابل باقي الأسبوع
SELECT 
 CASE Is_Weekend
   WHEN 1 THEN 'weekend'
   WHEN 0 THEN 'Weekday'
   END AS Day_Type, COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Is_Weekend
Order by Accident_Count ASC;


-- علاقة نوع الطريق × شدة الحادث
SELECT 
    Road_Type,
    Accident_Severity,
    COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Road_Type, Accident_Severity
ORDER BY Road_Type, Accident_Count DESC;


-- الطقس × شدة الحادث 
SELECT Weather,Accident_Severity,COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Weather, Accident_Severity
ORDER BY Weather, Accident_Count DESC;


-- ترتيب المناطق حسب الحوادث
SELECT Local_Authority_District,COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Local_Authority_District
ORDER BY Accident_Count DESC;


-- أكتر Time Slots خطورة
SELECT Time_Slot,COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Time_Slot
ORDER BY Accident_Count DESC;


--عدد الحوادث لكل موسم 
SELECT Season,COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Season
ORDER BY Accident_Count DESC;


--شدة الحوادث مقابل نوع الطريق
SELECT Road_Type, Accident_Severity,COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Road_Type, Accident_Severity
ORDER BY Road_Type, Accident_Count DESC;


-- المناطق الأعلى معدل حوادث لكل 1000 حادث 
WITH District_Accidents AS (
    SELECT 
        Local_Authority_District, 
        COUNT(*) AS Accident_Count
    FROM Road_Acc
    GROUP BY Local_Authority_District
)
SELECT 
    Local_Authority_District,
    Accident_Count,
    CONCAT(FORMAT((Accident_Count * 1000.0) / (SELECT COUNT(*) FROM Road_Acc), 'N2'), '%') AS Accidents_Per_1000
FROM District_Accidents
ORDER BY Accidents_Per_1000 DESC;



-- تحليل معامل الخطورة لكل نوع طريق
SELECT 
    Road_Type,
    CONCAT(FORMAT(
        SUM(CASE WHEN Accident_Severity = 'Fatal' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        'N2'
    ), '%') AS Fatality_Rate
FROM Road_Acc
GROUP BY Road_Type
ORDER BY Fatality_Rate DESC


--(الوقت × اليوم × خطورة الحوادث (تحليل تفصيلي للخطوره  
SELECT Time_Slot , Day_of_Week , Accident_Severity , COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Time_Slot, Day_of_Week, Accident_Severity
ORDER BY Time_Slot, Day_of_Week, Accident_Count DESC;


-- تحليل المناطق الريفية مقابل الحضرية حسب شدة الحادث
SELECT   Urban_or_Rural_Area , Accident_Severity , COUNT(*) AS Accident_Count
FROM Road_Acc
GROUP BY Urban_or_Rural_Area, Accident_Severity
ORDER BY Urban_or_Rural_Area, Accident_Count DESC;


--  أخطر 10 مناطق
WITH Ranked_Data AS (
    SELECT 
        Local_Authority_District,
        COUNT(*) AS Accident_Count,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS Rank
    FROM Road_Acc
    GROUP BY Local_Authority_District
)
SELECT 
    Local_Authority_District,
    Accident_Count,
    Rank
FROM Ranked_Data
WHERE Rank <= 10;


-- تحليل التغير السنوي في عدد الحوادث
SELECT 
    Year,
    COUNT(*) AS Accident_Count,
    CASE 
        WHEN LAG(COUNT(*)) OVER (ORDER BY Year) IS NOT NULL 
        THEN CONCAT(ROUND(((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY Year)) / CAST(LAG(COUNT(*)) OVER (ORDER BY Year) AS FLOAT)) * 100, 2), '%')
        ELSE '0%'
    END AS Yearly_Change_Percentage
FROM Road_Acc
GROUP BY Year
ORDER BY Year;


-- تحليل التغير الشهري في عدد الحوادث
WITH MonthlyCounts AS (
    SELECT
        FORMAT(Accident_Date, 'yyyy-MM') AS Month,
        COUNT(*) AS TotalAccidents
    FROM Road_Acc
    GROUP BY FORMAT(Accident_Date, 'yyyy-MM')
),
MonthlyLagged AS (
    SELECT
        Month,
        TotalAccidents,
        LAG(TotalAccidents) OVER (ORDER BY Month) AS PrevMonthAccidents
    FROM MonthlyCounts
)
SELECT 
    Month,
    TotalAccidents,
    CONCAT(
        CAST(
            ROUND(
                CASE 
                    WHEN PrevMonthAccidents IS NULL OR PrevMonthAccidents = 0 THEN 0
                    ELSE ((TotalAccidents - PrevMonthAccidents) * 100.0) / PrevMonthAccidents
                END, 
            2) AS float
        ),
        '%'
    ) AS PercentageChange
FROM MonthlyLagged
ORDER BY Month;


-- نسبة الحوادث الخطيرة
SELECT Year,
   CONCAT(FORMAT(
        SUM(CASE WHEN Accident_Severity = 'Slight' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 'N2'), '%') AS Slight,

   CONCAT(FORMAT(
        SUM(CASE WHEN Accident_Severity = 'Serious' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 'N2' ), '%') AS Serious,

   CONCAT(FORMAT(
        SUM(CASE WHEN Accident_Severity = 'Fatal' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 'N2' ), '%') AS Fatal
FROM Road_Acc
GROUP BY Year
ORDER BY Year;