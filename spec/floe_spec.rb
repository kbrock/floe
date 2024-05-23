RSpec.describe Floe do
  describe "logger=", "logger" do
    it "sets the logger" do
      old_logger = Floe.logger
      new_logger = "abc"

      Floe.logger = new_logger
      expect(Floe.logger).to eq(new_logger)

      Floe.logger = old_logger
    end
  end
end
