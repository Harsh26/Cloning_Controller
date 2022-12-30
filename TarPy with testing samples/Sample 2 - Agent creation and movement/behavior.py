'Testing out the agent behavior'

"""from Tartarus import Tarpy

tar = Tarpy()

print("Hi from agent at destination node")


mylist = tar.get_val(_Agent, "prime", _Port)

print(mylist)"""

#_IP = "localhost"
#_Port = 5004
#_Agent = "myagent"



from Tartarus import Tarpy
t = Tarpy()

def func():
    if _Port == 5002:
        print("I am the behaviour")
        print("I am at IP : " , _IP , " and Port : " , _Port)
        print("My job is to list prime numbers between 1 to 20")

        print("Platform value:")

        platform_list = t.get_val("", "k",_Port)

        print(platform_list)

        platform_list.append(6)

        t.assign_val("", "k", platform_list, _Port)

        print("New value to Platform:")

        print(t.get_val("", "k",_Port))

        n = 2
        l = [2]

        num = 3
        while(num != 20):
            flag = False
            for i in range(2, num):
                if num%i == 0:
                    flag = True
                    break
            if flag == False:
                l.append(num)
            
            num = num + 1

        print("List generated: ")
        print(l)

        print("I will move to the next node that is Node - 3")
        t.move_agent(_Agent, "localhost", 5004, _Port)

    elif _Port == 5004:
        print("I am at IP : " , _IP , " and Port : " , _Port)

        print("My job is to calculate factorial of 5")

        fact = 1

        for i in range(1, 6):
            fact *= i

        print("Factorial of 5 is: ")
        print(fact)

        print("I will move to the next node that is Node - 1")
        t.move_agent(_Agent, "localhost", 5000, _Port)

func()

