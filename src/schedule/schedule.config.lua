local StartMessages = {
	LightsOut = "Lights out! Head to your cabins and go to bed for the night.",
	FreeTime = "Free time! Explore, play, relax, or do whatever you like.",
	MorningRun = "Rise and shine! Follow your cabin leaders on a morning run around the lake.",
	Meal = "Meal time! Follow your cabin leaders to the dining area.",
	Activity = "Activity time! Follow your cabin leaders to an activity.",
}

local scheduleConfig = {
	DaytimeScale = 0.01,
	NightScaleFlat = 0.1,
	NightScaleFull = 0.2, 	-- This number is conversion from GAME HOURS to REAL LIFE SECONDS. i.e. if the number is .01,
	-- then each REAL LIFE SECOND will pass 0.01 game hours. 100 seconds to pass an entire hour
	StartingGameTime = 8.4,
	TimeScaleTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
	
	agenda = {
		{ Name = "LightsOut", Duration = 8.25, StartingTime = 0, DisplayName = "Lights Out", StartMessage = StartMessages.LightsOut },
		{ Name = "MorningRun", Duration = 0.25, DisplayName = "Morning Run", StartMessage = StartMessages.MorningRun },
		{ Name = "Breakfast", Duration = 0.5, DisplayName = "Breakfast", MealKey = "breakfast", StartMessage = StartMessages.Meal },
		{ Name = "OpenActivityChunk", Duration = 4.0, DisplayName = "Morning Activity", StartMessage = StartMessages.Activity },
		{ Name = "Lunch", Duration = 0.5, DisplayName = "Lunch", MealKey = "lunch", StartMessage = StartMessages.Meal },
		{ Name = "OpenActivityChunk", Duration = 4.0, DisplayName = "Afternoon Activity", StartMessage = StartMessages.Activity },
		{ Name = "Dinner", Duration = 0.5, DisplayName = "Dinner", MealKey = "dinner", StartMessage = StartMessages.Meal },
		{ Name = "FreeTime", Duration = 4.0, DisplayName = "Free Time", StartMessage = StartMessages.FreeTime },
		{ Name = "LightsOut", Duration = 2, DisplayName = "Lights Out", StartMessage = StartMessages.LightsOut },
	}
}

for i, c in pairs(scheduleConfig.agenda) do
	c.Index = i
end

return scheduleConfig