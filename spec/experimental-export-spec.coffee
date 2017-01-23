xdescribe "Experimental Export", ->
  toRows = (a)->a
  describe "simple case", ->

    it "'flattens' nested arrays in a 'vertical' fashion", ->
      expect( toRows [
        name: "Karl"
        tags: [
          "foo"
          "bar"
          "baz"
        ]
      ,
        name: "Otto"
        tags: [
          "bang"
          "boom"
        ]
      ]).to.eql [
        ["name" , "tags[]" ]
        ["Karl" , null     ]
        [null   , "foo"    ]
        [null   , "bar"    ]
        [null   , "baz"    ]
        ["Otto" , null     ]
        [null   , "bang"   ]
        [null   , "boom"   ]
      ]

