#language: en

@ldegen/irma#17
Feature: Support Per-Type ElasticSearch Indices

  As described in ldegen/irma#17 it is important that IRMa supports using
  more than one type per application and that each type can have its own elasticsearch
  index. The latter one is necessary because starting with Elasticsearch 6.x,
  it is no longer allowed to use more than one mapping within the same index.
  (This has always been confusing anyway, so imho: good riddance.)

  To maintain backward compatibility, IRMa still supports the global `index`
  setting, which will be the fall back that us used when a type does not
  specify an index.


  Background:
    Given the following irma.yaml
      """
      elasticSearch:
        index: test_apples

      types:
        potato:
          index: test_potatos
          attributes:
            - bar !fulltext

        apple:
          attributes:
            - foo !fulltext
      """
    And an index "test-potatos" with documents of type "Potato":
      | id | bar    |
      | 1  | feuer  |
      | 2  | wasser |

    And an index "test-apples" with documents of type "Apple":
      | id | foo        |
      | 3  | suppe      |
      | 4  | hackbraten |

    


  Scenario: Using a type-specific index
    When I search for an apple using the query string "feuer"
    Then there is a hit for document 1
    And there are no other hits

  Scenario: Using the default index
    When I search for a potato using the query string "hackbraten"
    Then there is a hit for document 4
    And there are no other hits


