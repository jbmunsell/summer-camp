local StartMessages = {
	LightsOut = "Lights out! Head to your cabins and go to bed for the night.",

	Meal = "Meal time! Go to the dining area.",
	MealOver = "Meal time is over! Put your dishes in the cleaning tent and ",

	FreeTime = "head to the campfire for roasting marshmallows.",
	Activity = "go play some games!",
}

local scheduleConfig = {
	-- DaytimeScale = 0.2,
	DaytimeScale = 0.01,
	NightScaleFlat = 0.05,
	NightScaleFull = 0.3, 	-- This number is conversion from GAME HOURS to REAL LIFE SECONDS. i.e. if the number is .01,
	-- then each REAL LIFE SECOND will pass 0.01 game hours; 100 seconds to pass an entire hour
	StartingGameTime = game:GetService("ReplicatedStorage").config.schedule.GameStartTime.Value,
	TimeScaleTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
	
	agenda = {
		{
			Name = "LightsOut",
			Duration = 8.0,
			StartingTime = 0,
			DisplayName = "Lights Out",
			StartMessage = StartMessages.LightsOut
		},
		-- {
		-- 	Name = "MorningRun",
		-- 	Duration = 0.25,
		-- 	DisplayName = "Morning Run",
		-- 	StartMessage = StartMessages.MorningRun
		-- },
		{
			Name = "Breakfast",
			Duration = 1.0,
			DisplayName = "Breakfast",
			MealKey = "breakfast",
			StartMessage = StartMessages.Meal
		},
		{
			Name = "OpenActivityChunk",
			Duration = 4.0,
			DisplayName = "Team Activities",
			StartMessage = StartMessages.MealOver .. StartMessages.Activity,
		},
		{
			Name = "Lunch",
			Duration = 1.0,
			DisplayName = "Lunch",
			MealKey = "lunch",
			StartMessage = StartMessages.Meal
		},
		{
			Name = "OpenActivityChunk",
			Duration = 4.0,
			DisplayName = "Team Activities",
			StartMessage = StartMessages.MealOver .. StartMessages.Activity
		},
		{
			Name = "Dinner",
			Duration = 1.0,
			DisplayName = "Dinner",
			MealKey = "dinner",
			StartMessage = StartMessages.Meal
		},
		{
			Name = "FreeTime",
			Duration = 2.0,
			DisplayName = "Free Time",
			StartMessage = StartMessages.MealOver .. StartMessages.FreeTime
		},
		{
			Name = "LightsOut",
			Duration = 3,
			DisplayName = "Lights Out",
			StartMessage = StartMessages.LightsOut
		},
	}
}

for i, c in pairs(scheduleConfig.agenda) do
	c.Index = i
end

return scheduleConfig