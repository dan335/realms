require 'dotenv/load'
require 'mongo'
require './commonFunctions.rb'

Mongo::Logger.logger.level = Logger::FATAL
mongo = Mongo::Client.new([ ENV['MONGO_URL'] ], :database => ENV['MONGO_DB'])



RSpec.describe "commonFunctions" do
    it "adds commas" do
        expect(number_with_commas(1000)).to eq("1,000")
        expect(number_with_commas(1000.00)).to eq("1,000.0")
    end


    it "grows population" do
        expect(getNewPopulation(100, 0.5, 0.5)).to eq(100)
        expect(getNewPopulation(100, 1.0, 0.5)).to be > (100)
        expect(getNewPopulation(100, 0.0, 0.5)).to be < (100)
    end


    it "gets new happiness" do
        # test tax
        expect(getNewHappiness(0.5, 0.325, nil, 1.0)).to be_between(0.499, 0.501)
        expect(getNewHappiness(0.5, 0.4, nil, 1.0)).to be < 0.5
        expect(getNewHappiness(0.5, 0.2, nil, 1.0)).to be > 0.5

        # test last lost battle
        expect(getNewHappiness(0.5, 0.325, Time.now, 1.0)).to be < 0.4751
        expect(getNewHappiness(0.5, 0.325, Time.now - 60 * 60 * 4, 1.0)).to be_between(0.499, 0.501)

        #test reputation
        expect(getNewHappiness(0.5, 0.325, nil, 1.0)).to be_between(0.499, 0.501)
        expect(getNewHappiness(0.5, 0.325, nil, 0.5)).to be < 0.5
        expect(getNewHappiness(0.5, 0.325, nil, 0.0)).to eq 0.45
    end

    it "slopeInterpolate works for tax rage" do
        expect(slopeInterpolate(0.325, 0.0, 1.0, 0.0, 1.0, 0.9)).to be_between(0.499, 0.501)
        expect(slopeInterpolate(0.0, 0.0, 1.0, 0.0, 1.0, 0.9)).to eq(0.0)
        expect(slopeInterpolate(1.0, 0.0, 1.0, 0.0, 1.0, 0.9)).to eq(1.0)
    end


    it "gets new reputation" do
        expect( getReputationFromAttack(1000, 1000, 1.0) ).to eq(1.0)
        expect( getReputationFromAttack(1000, 1000, 0.5) ).to eq(0.5)
        expect( getReputationFromAttack(1000, 0, 1.0) ).to eq(0.0)
    end
end