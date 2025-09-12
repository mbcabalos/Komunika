import tkinter as tki

def click():
    text_box.config(state="normal")
    text_box.delete("1.0", "end")         
    text_box.insert("1.0","Fuck you nigga")
    text_box.config(state="disabled")  


main = tki.Tk()
main.title("Test window")
main.geometry("300x300")

button = tki.Button(main, text="Click Me", command=click)
button.pack(pady=20)

text_box = tki.Text(main, height=10, width=40)
text_box.pack(pady=10)
text_box.insert("1.0","")
text_box.config(state="disabled")

main.mainloop()