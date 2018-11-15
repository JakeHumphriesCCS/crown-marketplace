module TempToPermCalculator
  module Steps
    class DaysPerWeek
      include JourneyStep

      attribute :days_per_week
      validates :days_per_week, presence: true, numericality: { only_integer: true }

      def next_step_class
        DayRate
      end
    end
  end
end