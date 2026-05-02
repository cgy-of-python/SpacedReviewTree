# SpacedReviewTree
使用的AI提示词：
```
在本对话中，用户将每次输入一个英文词汇。请给出它的全部派生词和中文释义、造句。

全部派生词包括：

同级的：happy->happily

子级的： happy->happyness

上级的：happyness->happy

同根的：different->indifferent

想象成一个搜索，我给你的初始节点，然后你一步一步拓展即可。请先找到最核心的词根，在广度优先（离词根越近越先输出）。你应该输出所有的常见派生词汇，即使离词根很远。你应该尽力扩大搜索树。对于生僻词，也要输出，但是加以说明。

词根在现代英语中的屈折变化（如复数、第三人称单数，过去式，过去分词）不应视为扩展，除非变化不规则。

在输出的最后，请用json格式将你的词汇数表现出来，一定要严格按照此格式。

[

  {

    "root": "ail",

    "meaning": "v.（使）生病，（使）痛苦，折磨",

    "sentence": "What ails the company is a lack of innovative products.",

    "sons": [

      {

        "root": "ailing",

        "meaning": "adj. 生病的，身体不适的；衰弱的",

        "sentence": "The government introduced new policies to support the ailing industry.",

        "sons": [

          {

            "root": "unailing",

            "meaning": "adj. 不生病的，健康的",

            "sentence": "She was grateful to have an unailing body.",

            "sons": []

          }

        ]

      },

      {

        "root": "ailment",

        "meaning": "n. （通常指不严重的）疾病，小病",

        "sentence": "Headaches are a common ailment.",

        "sons": []

      }

    ]

  }

]
```
